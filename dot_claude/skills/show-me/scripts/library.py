#!/usr/bin/env python3
"""Manage the local visual library and its canonical tag vocabulary."""
import argparse
from collections import Counter
from datetime import datetime
import fcntl
import hashlib
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shutil
import sys
import unicodedata
from urllib.parse import quote
import uuid


class VisibleText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hidden = 0
        self.words = []

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.hidden += 1
        if tag == 'iframe' and 'srcdoc' in dict(attrs):
            child = VisibleText()
            child.feed(dict(attrs)['srcdoc'])
            self.words.extend(child.words)

    def handle_endtag(self, tag):
        if tag in ('script', 'style'):
            self.hidden -= 1

    def handle_data(self, text):
        if not self.hidden:
            self.words.append(text)


def normalized(name):
    return re.sub(r'[\s_-]+', '', unicodedata.normalize('NFKC', name).casefold())


def names(tag):
    return [tag['id'], tag['label'], *tag['aliases']]


def resolve(catalog, value):
    for tag in catalog['tags']:
        if normalized(value) in map(normalized, names(tag)):
            return tag
    raise ValueError(f'未登録のタグ: {value}。tags で既存タグを確認してください。')


def check_names(catalog, candidates, excluding=None):
    for candidate in candidates:
        if not candidate.strip():
            raise ValueError('空のタグ名・別名は登録できません。')
        for tag in catalog['tags']:
            if tag['id'] != excluding and normalized(candidate) in map(normalized, names(tag)):
                raise ValueError(f'{candidate} は既存タグ {tag["label"]} と重複します。別名追加か統合を使ってください。')


def add_tag(catalog, tag_id, label, aliases, description):
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', tag_id):
        raise ValueError('タグ ID は小文字英数字とハイフンで指定してください。')
    check_names(catalog, [tag_id, label, *aliases])
    catalog['tags'].append(dict(id=tag_id, label=label, aliases=list(dict.fromkeys(aliases)), description=description))


def merge_tags(catalog, source_name, target_name):
    source, target = resolve(catalog, source_name), resolve(catalog, target_name)
    if source is target:
        raise ValueError('統合元と統合先が同じタグです。')
    if source.get('repository') or target.get('repository'):
        raise ValueError('発動元を保持するため、リポジトリタグは他のタグに統合できません。')
    target['aliases'] = list(dict.fromkeys([*target['aliases'], *names(source)]))
    for document in catalog['documents']:
        document['tags'] = list(dict.fromkeys(target['id'] if t == source['id'] else t for t in document['tags']))
    catalog['tags'].remove(source)


def repository_tag(catalog, repository):
    if not re.fullmatch(r'[^/\s]+/[^/\s]+', repository):
        raise ValueError('リポジトリは owner/repository で指定してください。')
    for tag in catalog['tags']:
        if tag.get('repository') == repository:
            return tag['id']
    tag_id = 'repo-' + hashlib.sha256(repository.encode()).hexdigest()[:12]
    label = repository.split('/')[1]
    if any(normalized(label) in map(normalized, names(t)) for t in catalog['tags']):
        label = repository
    add_tag(catalog, tag_id, label, [repository] if label != repository else [], f'{repository} の作業で作成した資料。')
    catalog['tags'][-1]['repository'] = repository
    return tag_id


def build(root, catalog):
    documents = []
    for document in catalog['documents']:
        path = Path(document['path'])
        if not path.is_absolute():
            path = root / path
        parser = VisibleText()
        parser.feed(path.read_text())
        documents.append({**document, 'href': quote(Path(os.path.relpath(path, root)).as_posix()), 'text': ' '.join(parser.words)})
    payload = json.dumps({'tags': catalog['tags'], 'documents': documents}, ensure_ascii=False).replace('<', '\\u003c')
    template = (Path(__file__).resolve().parents[1] / 'assets/library.html').read_text()
    target = root / 'index.html'
    temporary = root / 'index.html.tmp'
    temporary.write_text(template.replace('__LIBRARY_DATA__', payload))
    temporary.replace(target)


def register(root, catalog, args):
    source = args.file.expanduser().resolve(strict=True)
    if source.suffix.lower() not in ('.html', '.htm'):
        raise ValueError('HTML ファイルを指定してください。')
    tag_ids = list(dict.fromkeys(resolve(catalog, value)['id'] for value in args.tag))
    if args.id:
        previous = next((d for d in catalog['documents'] if d['id'] == args.id), None)
        if previous is None:
            raise ValueError(f'更新対象の文書がありません: {args.id}')
    else:
        previous = next((d for d in catalog['documents'] if d['source'] == str(source)), None)
    repository = args.repository or (previous.get('repository') if previous else None)
    if repository:
        tag_ids = list(dict.fromkeys([*tag_ids, repository_tag(catalog, repository)]))
    document_id = previous['id'] if previous else uuid.uuid4().hex[:12]
    now = datetime.now().astimezone().isoformat(timespec='seconds')
    if args.reference:
        location = str(source)
    else:
        destination = root / 'items' / document_id / 'index.html'
        destination.parent.mkdir(parents=True, exist_ok=True)
        if source != destination.resolve():
            shutil.copy2(source, destination)
        location = destination.relative_to(root).as_posix()
    document = dict(id=document_id, title=args.title, summary=args.summary, project=args.project,
                    tags=tag_ids, repository=repository, source=str(source), path=location,
                    registered=previous['registered'] if previous else now, updated=now,
                    status=args.status)
    if previous:
        catalog['documents'][catalog['documents'].index(previous)] = document
    else:
        catalog['documents'].append(document)
    return document_id


def parser():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--root', type=Path, default=Path.home() / 'visual-notes')
    commands = cli.add_subparsers(dest='command', required=True)
    commands.add_parser('init')
    commands.add_parser('build')
    commands.add_parser('tags')
    commands.add_parser('list')
    commands.add_parser('audit')
    tag = commands.add_parser('tag-add')
    tag.add_argument('id')
    tag.add_argument('label')
    tag.add_argument('--alias', action='append', default=[])
    tag.add_argument('--description', required=True)
    alias = commands.add_parser('tag-alias')
    alias.add_argument('tag')
    alias.add_argument('alias')
    merge = commands.add_parser('tag-merge')
    merge.add_argument('source')
    merge.add_argument('target')
    rename = commands.add_parser('tag-rename')
    rename.add_argument('tag')
    rename.add_argument('label')
    retag = commands.add_parser('retag')
    retag.add_argument('id')
    retag.add_argument('tags', nargs='+')
    add = commands.add_parser('add')
    add.add_argument('file', type=Path)
    add.add_argument('--id')
    add.add_argument('--title', required=True)
    add.add_argument('--summary', required=True)
    add.add_argument('--project', required=True)
    add.add_argument('--repository', help='発動元の owner/repository。中央台帳にリポジトリ名のタグを自動作成・付与する。')
    add.add_argument('--tag', action='append', required=True)
    add.add_argument('--status', choices=['検討中', '採用', '参考', '廃止'], default='参考')
    add.add_argument('--reference', action='store_true', help='原本の場所を参照する。既定は書庫へ HTML をコピーする。')
    return cli


def main():
    args = parser().parse_args()
    root = args.root.expanduser().resolve()
    root.mkdir(parents=True, exist_ok=True)
    # Multiple agent sessions share this catalog; serialize read-modify-write.
    with (root / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        catalog_path = root / 'catalog.json'
        if args.command == 'init' and not catalog_path.exists():
            catalog = {'tags': [], 'documents': []}
        else:
            catalog = json.loads(catalog_path.read_text())
        command = args.command
        if command == 'tags':
            print(json.dumps(catalog['tags'], ensure_ascii=False, indent=2))
            return
        if command == 'list':
            print(json.dumps(catalog['documents'], ensure_ascii=False, indent=2))
            return
        if command == 'audit':
            counts = Counter(t for d in catalog['documents'] for t in d['tags'])
            print(json.dumps([dict(**t, count=counts[t['id']], review='未使用' if not counts[t['id']] else '1 件のみ' if counts[t['id']] == 1 else '') for t in catalog['tags']], ensure_ascii=False, indent=2))
            return
        if command == 'tag-add':
            add_tag(catalog, args.id, args.label, args.alias, args.description)
        elif command == 'tag-alias':
            tag = resolve(catalog, args.tag)
            check_names(catalog, [args.alias], excluding=tag['id'])
            if normalized(args.alias) not in map(normalized, names(tag)):
                tag['aliases'].append(args.alias)
        elif command == 'tag-merge':
            merge_tags(catalog, args.source, args.target)
        elif command == 'tag-rename':
            tag = resolve(catalog, args.tag)
            check_names(catalog, [args.label], excluding=tag['id'])
            tag['aliases'] = list(dict.fromkeys([*tag['aliases'], tag['label']]))
            tag['label'] = args.label
        elif command == 'retag':
            document = next((d for d in catalog['documents'] if d['id'] == args.id), None)
            if document is None:
                raise ValueError(f'文書がありません: {args.id}')
            document['tags'] = list(dict.fromkeys(resolve(catalog, value)['id'] for value in args.tags))
            if document.get('repository'):
                document['tags'] = list(dict.fromkeys([*document['tags'], repository_tag(catalog, document['repository'])]))
            document['updated'] = datetime.now().astimezone().isoformat(timespec='seconds')
        elif command == 'add':
            print(register(root, catalog, args))
        if command != 'build':
            if catalog_path.exists():
                shutil.copy2(catalog_path, root / 'catalog.previous.json')
            temporary = root / 'catalog.json.tmp'
            temporary.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
            temporary.replace(catalog_path)
        build(root, catalog)
        print(root / 'index.html')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as error:
        sys.exit(str(error))
