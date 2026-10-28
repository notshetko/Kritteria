#!/usr/bin/env python3
"""Multi-provider lyric resolver: score sync quality, romaji and translation instead of first-hit wins."""
import sys, os, json, time, hashlib, re, base64, zlib, difflib, urllib.request, urllib.parse, xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home()/".cache"))) / "end4-pC" / "lyrics"
CACHE.mkdir(parents=True, exist_ok=True)
CACHE_TTL = 30 * 24 * 3600
MAX_CACHE_FILES = 250
MAX_CACHE_BYTES = 12 * 1024 * 1024
USER_AGENT = "end4-pC-lyrics/4.0 (AMLL TTML + Better Lyrics + NetEase + LRCLIB; desktop widget)"
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"

_RE_KANA = re.compile(r'[\u3040-\u30ff]')
_RE_HANGUL = re.compile(r'[\uac00-\ud7af]')
_RE_HAN = re.compile(r'[\u3400-\u4dbf\u4e00-\u9fff]')

def preferred_romanization(text, candidate=''):
    """Do not accept Japanese-style transliteration for Han-only Chinese lines."""
    text = text or ''
    han_only = bool(_RE_HAN.search(text)) and not _RE_KANA.search(text) and not _RE_HANGUL.search(text)
    if han_only:
        return romanize(text)
    return str(candidate or '').strip() or romanize(text)

def prune_cache(force=False):
    now=time.time(); entries=[]
    for p in CACHE.glob('*.json'):
        try:
            st=p.stat()
            if force or now-st.st_mtime > CACHE_TTL: p.unlink(missing_ok=True)
            else: entries.append((st.st_mtime,st.st_size,p))
        except OSError: pass
    entries.sort(reverse=True); total=sum(e[1] for e in entries)
    while entries and (len(entries)>MAX_CACHE_FILES or total>MAX_CACHE_BYTES):
        _,size,p=entries.pop();
        try: p.unlink(missing_ok=True); total-=size
        except OSError: pass

def norm(s): return re.sub(r'[^\w]+',' ',(s or '').casefold(),flags=re.UNICODE).strip()
def get_json(url, timeout=3.2, headers=None):
    h={"User-Agent":USER_AGENT,"Accept":"application/json, text/plain, */*","Referer":"https://music.163.com/"}
    if headers: h.update(headers)
    req=urllib.request.Request(url,headers=h)
    with urllib.request.urlopen(req,timeout=timeout) as r: return json.loads(r.read().decode('utf-8','replace'))
def cache_path(title,artist,duration,album=''):
    key=hashlib.sha256(('v6|'+norm(title)+'|'+norm(artist)+'|'+norm(album)+'|'+str(int(duration))).encode()).hexdigest()
    return CACHE/(key+'.json')
def seconds(v):
    if not v: return None
    v=str(v).strip()
    try:
        if v.endswith('ms'): return float(v[:-2])/1000
        if v.endswith('s'): return float(v[:-1])
        if ':' in v:
            parts=v.split(':')
            if len(parts)==3: return float(parts[0])*3600+float(parts[1])*60+float(parts[2])
            if len(parts)==2: return float(parts[0])*60+float(parts[1])
        return float(v)
    except (ValueError,TypeError): return None

def clean_text(s):
    return re.sub(r'\s+', ' ', (s or '')).strip()

def parse_lrc(raw):
    out=[]
    for line in (raw or '').splitlines():
        m=re.match(r'^\[(\d{1,3}):(\d{2}(?:\.\d{1,3})?)\](.*)$',line.strip())
        if m:
            txt=m.group(3).strip()
            if txt and not re.match(r'^(作词|作曲|编曲|制作|演唱|lyrics by|written by|composer|producer)\s*[:：]', txt, re.I):
                out.append({'time':int(m.group(1))*60+float(m.group(2)),'text':txt,'romaji':'','translation':'','words':[]})
    return sorted(out,key=lambda x:x['time'])

def _role(el):
    return (el.attrib.get('{http://www.w3.org/ns/ttml#metadata}role') or el.attrib.get('role') or '').lower()

def _plain_main(el):
    chunks=[]
    def walk(node):
        role=_role(node)
        if role in ('x-translation','x-roman','x-bg'):
            return
        if node.text: chunks.append(node.text)
        for ch in list(node):
            walk(ch)
            if ch.tail: chunks.append(ch.tail)
    walk(el)
    return clean_text(''.join(chunks))

def _aux_text(node):
    chunks=[]
    def walk(el):
        if el.text: chunks.append(el.text)
        for child in list(el):
            walk(child)
            if child.tail: chunks.append(child.tail)
    walk(node)
    return clean_text(''.join(chunks))

def parse_ttml(raw):
    """Parse AMLL/Apple TTML without flattening translation and romanization into the main lyric."""
    try: root=ET.fromstring(raw)
    except Exception: return []
    lines=[]
    # Apple-style auxiliary tracks live in <head>; map each <text for="L1"> to itunes:key.
    metadata_aux={}
    for el in root.iter():
        tag=el.tag.split('}')[-1].lower()
        if tag not in ('text','translation','transliteration'): continue
        key=el.attrib.get('for')
        if not key: continue
        parent_role=tag
        if tag == 'text':
            # Determine whether the parent track is a translation or transliteration.
            for par in root.iter():
                if el in list(par):
                    pt=par.tag.split('}')[-1].lower()
                    if pt in ('translation','transliteration'):
                        parent_role=pt; break
        if parent_role in ('translation','transliteration'):
            bucket=metadata_aux.setdefault(key, {})
            bucket['translation' if parent_role=='translation' else 'romaji']=_aux_text(el)
    for p in root.iter():
        if p.tag.split('}')[-1] != 'p': continue
        start=seconds(p.attrib.get('begin') or p.attrib.get('start'))
        end=seconds(p.attrib.get('end'))
        if start is None: continue
        key=next((value for attr,value in p.attrib.items() if attr == 'key' or attr.endswith('}key')), '')
        meta=metadata_aux.get(key,{})
        txt=_plain_main(p)
        translations=[]; roman=[]
        for child in p.iter():
            if child is p: continue
            role=_role(child)
            if role == 'x-translation': translations.append(_aux_text(child))
            elif role == 'x-roman': roman.append(_aux_text(child))
        translation=next((x for x in translations if x), meta.get('translation',''))
        romaji=next((x for x in roman if x), meta.get('romaji',''))
        # Real word timing only from direct timed children that are not auxiliary tags.
        words=[]
        for el in p.iter():
            if el is p or el.tag.split('}')[-1] not in ('span','w'): continue
            if _role(el) in ('x-translation','x-roman','x-bg'): continue
            # Skip container spans that contain nested timed spans; only leaves become word entries.
            if any(c.tag.split('}')[-1] in ('span','w') for c in list(el)): continue
            wtxt=clean_text(''.join(el.itertext()))
            wb=seconds(el.attrib.get('begin') or el.attrib.get('start'))
            we=seconds(el.attrib.get('end'))
            if wtxt and wb is not None and we is not None and we > wb:
                words.append({'text':wtxt,'start':wb,'end':we})
        if not txt:
            # Sometimes word spans are all the main content after whitespace normalization.
            txt=clean_text(''.join(w['text'] for w in words))
        if not txt: continue
        lines.append({'time':start,'end':end if end and end>start else None,'text':txt,'romaji':preferred_romanization(txt,romaji),'translation':translation,'words':words})
    lines.sort(key=lambda x:x['time'])
    for i,line in enumerate(lines):
        if not line.get('end'):
            line['end']=lines[i+1]['time'] if i+1<len(lines) else line['time']+4
    # Normalize nested word times and guard against malformed upstream timestamps.
    for line in lines:
        valid=[]
        for w in sorted(line.get('words',[]), key=lambda a:a['start']):
            if w['end'] > w['start'] and (not valid or w['start'] >= valid[-1]['start']): valid.append(w)
        line['words']=valid
    return lines

def parse_qrc(raw):
    """Parse common QQ QRC line/word millisecond timing into the widget's word model."""
    out=[]
    raw = raw or ''
    # Better Lyrics wraps QRC in XML (LyricContent); unwrap XML attributes/elements first.
    if '<' in raw and '>' in raw:
        try:
            wrapper=ET.fromstring(raw)
            candidates=[]
            for node in wrapper.iter():
                for attr,value in node.attrib.items():
                    if attr.split('}')[-1].lower() in ('lyriccontent','content') and value:
                        candidates.append(value)
                if node.text and re.search(r'^\s*\[\d+,\d+\]',node.text): candidates.append(node.text)
            if candidates: raw='\n'.join(candidates)
        except Exception: pass
    for row in raw.splitlines():
        m=re.match(r'^\[(\d+),(\d+)\](.*)$', row.strip())
        if not m: continue
        stamp=float(m.group(1))/1000.0
        body=m.group(3)
        word_matches=list(re.finditer(r'(.*?)\((\d+),(\d+)\)', body))
        words=[]
        if word_matches:
            for wm in word_matches:
                text=wm.group(1)
                if not text: continue
                begin=float(wm.group(2))/1000.0
                dur=float(wm.group(3))/1000.0
                if dur>0: words.append({'text':text,'start':begin,'end':begin+dur})
            txt=''.join(w['text'] for w in words).strip()
        else:
            txt=body.strip()
        if txt:
            out.append({'time':stamp,'end':stamp+max(.5,float(m.group(2))/1000.0),'text':txt,'romaji':romanize(txt),'translation':'','words':words})
    return sorted(out,key=lambda a:a['time'])

def decode_kugou_krc(raw):
    """Decode Kugou KRC payload when a provider returns KRC rather than LRC."""
    try:
        data=base64.b64decode(raw)
        key=bytes([0x40,0x47,0x61,0x77,0x5E,0x32,0x74,0x47,0x51,0x36,0x31,0x2D,0xCE,0xD2,0x6E,0x69])
        plain=bytes(b ^ key[i % len(key)] for i,b in enumerate(data[4:]))
        try: return zlib.decompress(plain).decode('utf-8','replace')
        except Exception: return plain.decode('utf-8','replace')
    except Exception: return ''

def match_item(item,title,artist):
    names=' '.join(item.get('musicNames') or [])
    artists=' '.join(item.get('artistNames') or [])
    nt,na=norm(title),norm(artist); nn,nar=norm(names),norm(artists)
    return bool(nt and na and (nt in nn or nn in nt) and (na in nar or nar in na))

def fetch_amll(title,artist,duration=0,album=''):
    base='https://api.amll.dev/v1/lyrics/'
    try:
        q=urllib.parse.urlencode({'musicName':title,'artistName':artist,'page':'1','pageSize':'10'})
        result=get_json(base+'search?'+q, timeout=3.0)
        data=result.get('data',{}) if isinstance(result,dict) else {}
        items=data.get('items',[]) if isinstance(data,dict) else []
        item=next((x for x in items if match_item(x,title,artist)),None)
        if not item: return [],''
        got=get_json(base+'get?'+urllib.parse.urlencode({'id':item.get('id')}), timeout=3.2)
        song=got.get('data',{}) if isinstance(got,dict) else {}
        lines=parse_ttml(song.get('lyrics',''))
        if lines:
            for line in lines:
                line['romaji']=preferred_romanization(line['text'],line.get('romaji'))
            return lines, 'AMLL TTML'
    except Exception: pass
    return [],''

def fetch_betterlyrics(title,artist,duration,album='',variant=''):
    """Better Lyrics/Boidu caches: syllable TTML, QQ QRC, and Kugou line LRC."""
    params={'s':title,'a':artist,'al':album or '','d':str(max(1,int(duration)))}
    path=('/'+variant.strip('/') if variant else '')
    for base in ('https://api.betterlyrics.org','https://lyrics-api.boidu.dev'):
        try:
            url=base+path+'/getLyrics?'+urllib.parse.urlencode(params)
            payload=get_json(url,timeout=4.0)
            raw=payload.get('ttml') or payload.get('lyrics') or payload.get('lrc') or ''
            if not raw: continue
            if raw.lstrip().startswith('<'):
                lines=parse_ttml(raw)
                if not lines and variant.strip('/')=='qq': lines=parse_qrc(raw)
            else:
                lines=parse_lrc(raw)
                if not lines: lines=parse_qrc(raw)
                if not lines and variant.strip('/')=='kugou':
                    decoded=decode_kugou_krc(raw)
                    lines=parse_lrc(decoded) or parse_qrc(decoded)
            if not lines: continue
            for line in lines:
                line['romaji']=preferred_romanization(line['text'],line.get('romaji'))
            label='Better Lyrics'+(' · '+variant.strip('/') if variant else ' · TTML')
            if 'boidu.dev' in base: label+=' (Boidu legacy)'
            return lines,label
        except Exception: continue
    return [],''

def _nearest(entries,stamp,key='text'):
    if not entries: return ''
    best=min(entries,key=lambda x:abs(x['time']-stamp))
    return best.get(key,'') if abs(best['time']-stamp)<0.50 else ''

def fetch_netease(title, artist, duration, album=''):
    """Search NetEase Cloud Music and retrieve lyrics, translation (tlyric/ytlrc) and romanization."""
    nt,na=norm(title),norm(artist)
    for endpoint in ('https://music.163.com/api/cloudsearch/pc','https://music.163.com/api/search/get'):
        try:
            params={'s':f'{title} {artist}'.strip(),'type':1,'limit':15,'offset':0}
            if 'cloudsearch' in endpoint: params['total']='true'
            result=get_json(endpoint+'?'+urllib.parse.urlencode(params),timeout=3.6,
                            headers={'Referer':'https://music.163.com/','Origin':'https://music.163.com'})
            root=result.get('result') or result.get('data') or {}
            songs=root.get('songs') or []
            ranked=[]
            for song in songs:
                name=song.get('name') or song.get('songName') or ''
                artists=' '.join((a.get('name') or '') for a in (song.get('artists') or song.get('ar') or []) if isinstance(a,dict))
                sn,sa=norm(name),norm(artists)
                if not sn or not sa: continue
                title_ok=nt==sn or (len(nt)>3 and (nt in sn or sn in nt))
                artist_ok=na==sa or (len(na)>3 and (na in sa or any(norm(a.get('name') or '') in na for a in (song.get('artists') or song.get('ar') or []) if isinstance(a,dict))))
                if not (title_ok and artist_ok): continue
                dur=float(song.get('duration') or song.get('dt') or 0)/1000
                delta=abs(dur-duration) if duration>0 and dur>0 else 0
                if duration>0 and dur>0 and delta>max(18,duration*.12): continue
                ranked.append(((0 if nt==sn else 1)+(0 if na==sa else 1)+delta/1000,song))
            if ranked:
                song=sorted(ranked,key=lambda x:x[0])[0][1]
                sid=song.get('id')
                for lyric_endpoint in ('https://music.163.com/api/song/lyric/v1','https://music.163.com/api/song/lyric'):
                    try:
                        args={'id':sid,'cp':'false','lv':-1,'tv':-1,'rv':-1,'kv':-1,'yv':-1,'ytv':-1,'yrv':-1}
                        payload=get_json(lyric_endpoint+'?'+urllib.parse.urlencode(args),timeout=3.5,
                                         headers={'Referer':'https://music.163.com/','Origin':'https://music.163.com'})
                        lrc=((payload.get('lrc') or {}).get('lyric') or '')
                        if not lrc: continue
                        lines=parse_lrc(lrc)
                        if not lines: continue
                        roma=parse_lrc(((payload.get('romalrc') or {}).get('lyric') or ''))
                        trans_raw=((payload.get('tlyric') or {}).get('lyric') or '') or ((payload.get('ytlrc') or {}).get('lyric') or '')
                        translated=parse_lrc(trans_raw)
                        for line in lines:
                            line['romaji']=preferred_romanization(line['text'],_nearest(roma,line['time']))
                            line['translation']=_nearest(translated,line['time'])
                        return lines,'NetEase Cloud Music'
                    except Exception: continue
        except Exception: continue
    return [],''

def fetch_lrclib(title,artist,duration,album=''):
    base='https://lrclib.net/api/'
    urls=[base+'get?'+urllib.parse.urlencode({'track_name':title,'artist_name':artist,'album_name':album,'duration':int(duration)}),base+'search?'+urllib.parse.urlencode({'track_name':title,'artist_name':artist})]
    for url in urls:
        try: data=get_json(url,timeout=2.8)
        except Exception: continue
        candidates=data if isinstance(data,list) else [data]
        for d in candidates:
            if not isinstance(d,dict) or not d.get('syncedLyrics'): continue
            if norm(title) not in norm(d.get('trackName','')) and norm(d.get('trackName','')) not in norm(title): continue
            if norm(artist) not in norm(d.get('artistName','')) and norm(d.get('artistName','')) not in norm(artist): continue
            lines=parse_lrc(d['syncedLyrics'])
            if lines: return lines,'LRCLIB'
    return [],''

def fetch_liriqo(title,artist,duration,album=''):
    """Ask a multi-provider resolver for TTML/QQ/Kugou/NetEase/YTM and preserve every candidate."""
    params={'title':title,'artist':artist}
    if duration and duration > 0: params['duration']=int(duration)
    url='https://api.liriqo-alfarrizi.my.id/v1/lyrics?'+urllib.parse.urlencode(params)
    try: payload=get_json(url,timeout=6.0,headers={'Accept':'application/json'})
    except Exception: return []
    tracks=payload.get('tracks') or ([payload.get('primary')] if payload.get('primary') else [])
    results=[]
    for track in tracks:
        if not isinstance(track,dict): continue
        provider=str(track.get('upstreamProvider') or track.get('provider') or 'LiriQo')
        lines=[]
        timed=track.get('timed') or []
        words_by_line=track.get('words') or []
        for j,line in enumerate(timed):
            if not isinstance(line,dict): continue
            text=clean_text(str(line.get('text') or ''))
            if not text: continue
            start=seconds(line.get('start'))
            end=seconds(line.get('end'))
            # LiriQo's numeric timestamps are milliseconds; textual timestamps may already be seconds.
            if isinstance(line.get('start'),(int,float)) and start is not None: start/=1000
            if isinstance(line.get('end'),(int,float)) and end is not None: end/=1000
            if start is None: continue
            words=[]
            source_words=line.get('words') or (words_by_line[j] if j < len(words_by_line) and isinstance(words_by_line[j],list) else [])
            for word in source_words:
                if not isinstance(word,dict): continue
                ws=seconds(word.get('start')); we=seconds(word.get('end'))
                if isinstance(word.get('start'),(int,float)) and ws is not None: ws/=1000
                if isinstance(word.get('end'),(int,float)) and we is not None: we/=1000
                wt=clean_text(str(word.get('text') or ''))
                if wt and ws is not None and we is not None and we>ws:
                    words.append({'text':wt,'start':ws,'end':we})
            lines.append({'time':start,'end':end if end and end>start else None,'text':text,'romaji':'','translation':'','words':words})
        if not lines and track.get('ttml'): lines=parse_ttml(track['ttml'])
        if not lines and track.get('lrc'): lines=parse_lrc(track['lrc'])
        if not lines and track.get('qrc'): lines=parse_qrc(track['qrc'])
        if not lines and track.get('krc'):
            decoded=decode_kugou_krc(track['krc']); lines=parse_lrc(decoded) or parse_qrc(decoded)
        if not lines: continue
        native_translation=track.get('translation') or track.get('translations') or ''
        if isinstance(native_translation,list): trans_rows=[clean_text(str(x)) for x in native_translation]
        else:
            native_translation=str(native_translation)
            parsed=parse_lrc(native_translation)
            trans_rows=[x['text'] for x in parsed] if parsed else [clean_text(x) for x in native_translation.splitlines() if clean_text(x)]
        # Track translation can be whole-line text or timestamped LRC; align by index only if lengths match.
        if trans_rows and len(trans_rows)==len(lines):
            for line,tr in zip(lines,trans_rows): line['translation']=tr
        roma=track.get('romanization') or track.get('romaji') or ''
        if isinstance(roma,list) and len(roma)==len(lines):
            for line,r in zip(lines,roma): line['romaji']=clean_text(str(r))
        for line in lines:
            line['romaji']=preferred_romanization(line['text'],line.get('romaji'))
        sync_level=str(track.get('syncLevel') or '').strip().lower()
        label='LiriQo · '+provider+(' · '+sync_level if sync_level else '')
        results.append((lines,label))
    return results

def _sync_signature(text):
    """Comparable Unicode signature for a line and its timed word fragments."""
    return re.sub(r'[^\w]+', '', clean_text(text).casefold(), flags=re.UNICODE)

def prepare_candidate(lines):
    """Keep one provider's line/timing together; discard word timings that don't spell that line."""
    prepared = []
    for source_line in lines or []:
        if not isinstance(source_line, dict):
            continue
        line = dict(source_line)
        text = clean_text(str(line.get('text') or ''))
        if not text:
            continue
        try:
            start = float(line.get('time', 0))
        except (TypeError, ValueError):
            continue
        if start < 0:
            continue
        line['time'] = start
        try:
            end = float(line.get('end') or 0)
        except (TypeError, ValueError):
            end = 0
        line['end'] = end if end > start else None
        words = []
        for word in (line.get('words') or []):
            if not isinstance(word, dict):
                continue
            try:
                ws, we = float(word.get('start')), float(word.get('end'))
            except (TypeError, ValueError):
                continue
            wt = clean_text(str(word.get('text') or word.get('word') or ''))
            if not wt or ws < 0 or we <= ws:
                continue
            # Timings wildly outside this line are usually another provider/version's timing.
            if ws < start - 1.5 or (line['end'] and we > line['end'] + 2.0):
                continue
            item = dict(word)
            item.update({'text': wt, 'start': ws, 'end': we})
            words.append(item)
        words.sort(key=lambda item: (item['start'], item['end']))
        # Remove accidental duplicate/overlapping fragments without altering valid syllable order.
        clean_words = []
        for word in words:
            if clean_words and word['start'] < clean_words[-1]['start']:
                continue
            if clean_words and word['start'] == clean_words[-1]['start'] and word['text'] == clean_words[-1]['text']:
                continue
            clean_words.append(word)
        words = clean_words
        line['text'] = text
        line['words'] = words if len(words) > 1 else []
        if line['words']:
            source_sig = _sync_signature(text)
            words_sig = _sync_signature(''.join(w['text'] for w in line['words']))
            similarity = difflib.SequenceMatcher(None, source_sig, words_sig, autojunk=False).ratio()
            # If the fragments don't spell the displayed lyric, their timings cannot safely drive the ball.
            if not source_sig or not words_sig or similarity < 0.88:
                line['words'] = []
            else:
                for word in line['words']:
                    if _RE_KANA.search(text) and not _RE_HANGUL.search(text):
                        word['romaji'] = str(word.get('romaji') or romanize_japanese(word['text']) or word['text'])
                    else:
                        word['romaji'] = preferred_romanization(word['text'], word.get('romaji')) or word['text']
                # Word-level romanization is the geometry used by the karaoke highlight and ball.
                # Keep the whole line's visible romanization consistent with those exact timed fragments.
                word_roman = ' '.join(w.get('romaji') or w['text'] for w in line['words']).strip()
                if word_roman and (_RE_KANA.search(text) or _RE_HANGUL.search(text)):
                    line['romaji'] = word_roman
        line['romaji'] = preferred_romanization(text, line.get('romaji'))
        line['translation'] = clean_text(str(line.get('translation') or ''))
        prepared.append(line)
    prepared.sort(key=lambda item: item['time'])
    # A source with duplicate/descending timestamps makes the line wheel and ball stutter.
    result = []
    for line in prepared:
        if result and line['time'] <= result[-1]['time']:
            # Repeated timestamps are ambiguous for a single-line wheel. Keep the first
            # row from this provider instead of letting activeIndex alternate/flicker.
            continue
        result.append(line)
    return result

def score_candidate(lines,source,title,artist,duration):
    """Score content and matching timed words first; native translation/romanization break ties."""
    if not lines: return -1
    content=sum(len(x.get('text','').strip()) for x in lines)
    translation=sum(bool((x.get('translation') or '').strip()) for x in lines)
    romanized=sum(bool((x.get('romaji') or '').strip()) for x in lines)
    word_lines=sum(len(x.get('words') or [])>1 for x in lines)
    # Value coherent syllable/word timing most; native translation is a useful tie-breaker,
    # but must not outrank a materially better synchronized lyric just because it has metadata.
    coverage = len(lines) / max(1, min(80, round((duration or 180) / 4.0)))
    score=min(len(lines),80)*0.7 + min(content,3500)/110 + min(translation,len(lines))*1.05 + min(romanized,len(lines))*0.35 + min(word_lines,len(lines))*6.0 + min(1.0, coverage)*2.0
    low=source.casefold()
    if 'syllable' in low: score+=6.0
    elif 'word' in low: score+=4.0
    elif 'line' in low: score+=1.0
    if 'better lyrics' in low or 'boidu' in low: score+=2.5
    if 'amll' in low or 'apple music' in low: score+=1.6
    if 'netease' in low: score+=1.6
    if 'lrclib' in low: score+=0.0
    if duration and lines:
        last=float(lines[-1].get('time') or 0)
        if last > duration+12: score-=6
    return score

def resolve_lyrics(title,artist,duration,album=''):
    # Query sources in parallel. This avoids making the user wait through a long serial fallback chain.
    providers=[
        ('LiriQo',lambda:fetch_liriqo(title,artist,duration,album)),
        ('Better Lyrics TTML',lambda:fetch_betterlyrics(title,artist,duration,album,'')),
        ('Better Lyrics QQ',lambda:fetch_betterlyrics(title,artist,duration,album,'qq')),
        ('Better Lyrics Kugou',lambda:fetch_betterlyrics(title,artist,duration,album,'kugou')),
        ('AMLL TTML',lambda:fetch_amll(title,artist,duration,album)),
        ('NetEase Cloud Music',lambda:fetch_netease(title,artist,duration,album)),
        ('LRCLIB',lambda:fetch_lrclib(title,artist,duration,album)),
    ]
    results=[]
    with ThreadPoolExecutor(max_workers=7) as pool:
        futures={pool.submit(fn):name for name,fn in providers}
        for future in as_completed(futures):
            try:
                result=future.result()
                # LiriQo exposes all candidates; score each independently with our local rubric.
                if futures[future] == 'LiriQo' and isinstance(result,list):
                    candidates=result
                else:
                    candidates=[result]
                for lines,label in candidates:
                    if lines:
                        # Never combine lines/timing across providers: a candidate stays atomic.
                        prepared = prepare_candidate(lines)
                        if prepared:
                            results.append((score_candidate(prepared,label or futures[future],title,artist,duration),prepared,label or futures[future]))
            except Exception: pass
    if not results: return [],''
    results.sort(key=lambda x:x[0],reverse=True)
    selected, source = results[0][1], results[0][2]
    return selected,source

def romanize_japanese(text):
    """Use Japanese reading rules even for kanji-only fragments inside a Japanese line."""
    if not text or not text.strip(): return ''
    try:
        from pykakasi import kakasi
        converter = kakasi()
        converted = converter.convert(text)
        result = ' '.join(p.get('hepburn', '') for p in converted)
        return re.sub(r'\s+', ' ', result).strip()
    except Exception:
        return ''

def romanize(text):
    if not text or not text.strip(): return ''
    try:
        # Japanese is selected only when actual kana are present. Han-only text is
        # ambiguous, so favor Chinese pinyin rather than accidentally displaying Japanese.
        if _RE_KANA.search(text) and not _RE_HANGUL.search(text):
            return romanize_japanese(text)
        if _RE_HANGUL.search(text):
            from hangul_romanize import Transliter
            from hangul_romanize.rule import academic
            return re.sub(r'\s+',' ',Transliter(academic).translit(text)).strip()
    except Exception: pass
    try:
        if _RE_HAN.search(text):
            from pypinyin import lazy_pinyin
            result=' '.join(lazy_pinyin(text,errors=lambda x:list(x),strict=False))
            return re.sub(r'\s+([，。！？、：；,.!?;:])',r'\1',result).strip()
    except Exception: pass
    return ''

def serialize_lines(lines, source):
    """Serialize five fields per lyric row: timestamp, text, romanization, translation, timed words."""
    out=[]
    for line in lines:
        text=urllib.parse.quote(str(line.get('text','')).replace('§',' '),safe='')
        roma=urllib.parse.quote(preferred_romanization(str(line.get('text','')), line.get('romaji')).replace('§',' '),safe='')
        translation=urllib.parse.quote(str(line.get('translation','')).replace('§',' '),safe='')
        words=[]
        for w in line.get('words',[]):
            try:
                start=float(w['start']); end=float(w['end'])
                if not (end>start): continue
                wt=urllib.parse.quote(str(w.get('text','')).replace('~',' ').replace('§',' '),safe='')
                wr=urllib.parse.quote(str(w.get('romaji','') or romanize(str(w.get('text','')))).replace('~',' ').replace('§',' '),safe='')
                words.append(f'{start:.3f},{end:.3f},{wt},{wr}')
            except Exception: continue
        out.extend([str(float(line['time'])),text,roma,translation,'~'.join(words)])
    out.extend(['__SOURCE__',urllib.parse.quote(source,safe=''),'ok'])
    return '§'.join(out)

def main():
    if len(sys.argv)>1 and sys.argv[1] in ('--clear-cache','--clear-cache-force'):
        prune_cache(force=True); print('cache_cleared',flush=True); return
    prune_cache()
    if len(sys.argv)<4: print('no_info',flush=True); return
    title,artist=sys.argv[1],sys.argv[2]
    try: duration=float(sys.argv[3])
    except Exception: duration=0
    album=sys.argv[4] if len(sys.argv)>4 else ''
    if not title.strip() or not artist.strip(): print('no_info',flush=True); return
    cp=cache_path(title,artist,duration,album)
    lines=[]; source=''
    try:
        if time.time()-cp.stat().st_mtime<CACHE_TTL:
            cached=json.loads(cp.read_text())
            if cached.get('lines'): lines,source=cached['lines'],cached.get('source','')
    except Exception: pass
    if not lines: lines,source=resolve_lyrics(title,artist,duration,album)
    if not lines: print('not_found',flush=True); return
    # Never generate machine translations. Native provider translations are retained only
    # for source-quality scoring; the widget displays the original lyrics and romanization.
    # Clear stale auto-translated cache entries created by earlier V16 builds.
    if 'traducción automática' in source.casefold() or 'traduccion automatica' in source.casefold():
        for line in lines:
            line['translation'] = ''
        source = re.sub(r'\s*[·|/-]?\s*traducci[oó]n autom[aá]tica', '', source, flags=re.I).strip()
    try: cp.write_text(json.dumps({'lines':lines,'source':source},ensure_ascii=False))
    except Exception: pass
    print(serialize_lines(lines,source),flush=True)

if __name__=='__main__': main()
