import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('library.py')
spec = importlib.util.spec_from_file_location('library', SCRIPT)
library = importlib.util.module_from_spec(spec)
spec.loader.exec_module(library)


class TagVocabularyTest(unittest.TestCase):
    def test_repository_tags_reuse_identity_and_separate_same_names(self):
        catalog = {'tags': [], 'documents': []}
        first = library.repository_tag(catalog, 'owner/product')
        self.assertEqual(first, library.repository_tag(catalog, 'owner/product'))
        second = library.repository_tag(catalog, 'another/product')
        self.assertNotEqual(first, second)
        self.assertEqual([t['label'] for t in catalog['tags']], ['product', 'another/product'])
        with self.assertRaises(ValueError):
            library.merge_tags(catalog, first, second)

    def test_aliases_resolve_and_colliding_names_are_rejected(self):
        catalog = {'tags': [], 'documents': []}
        library.add_tag(catalog, 'ai-agent', 'AI Agent', ['AI エージェント'], 'Agent の設計')
        self.assertEqual(library.resolve(catalog, 'ＡＩ－Ａｇｅｎｔ')['id'], 'ai-agent')
        self.assertEqual(library.resolve(catalog, 'aiエージェント')['id'], 'ai-agent')
        with self.assertRaises(ValueError):
            library.add_tag(catalog, 'different-id', 'AI エージェント', [], '重複')
        self.assertEqual(len(catalog['tags']), 1)

    def test_merge_preserves_references_and_old_names(self):
        catalog = {'tags': [], 'documents': [{'tags': ['agent', 'ai-agent']}, {'tags': ['agent']}]}
        library.add_tag(catalog, 'ai-agent', 'AI Agent', [], '設計')
        library.add_tag(catalog, 'agent', 'エージェント', ['自律 Agent'], '設計')
        library.merge_tags(catalog, 'agent', 'ai-agent')
        self.assertEqual([d['tags'] for d in catalog['documents']], [['ai-agent'], ['ai-agent']])
        for old in ['agent', 'エージェント', '自律 Agent']:
            self.assertEqual(library.resolve(catalog, old)['id'], 'ai-agent')


class LibraryWorkflowTest(unittest.TestCase):
    def test_registration_update_and_rebuild_survive_reopening(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / 'archive'
            source = Path(temporary) / '図 #1.html'
            source.write_text('<title>資料</title><style>hiddenStyle</style><p>検索できる本文</p>')
            def run(*args, ok=True):
                result = subprocess.run([sys.executable, str(SCRIPT), '--root', str(root), *args], capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, ok, result.stderr)
                return result
            run('init')
            run('tag-add', 'architecture', '設計', '--alias', 'アーキテクチャ', '--description', '構造と責務')
            before = (root / 'catalog.json').read_text()
            arguments = ['add', str(source), '--title', '</script><script>alert(1)</script>', '--summary', '確認用', '--project', 'owner/repo']
            run(*arguments, '--tag', 'unknown', ok=False)
            self.assertEqual((root / 'catalog.json').read_text(), before)
            run(*arguments, '--tag', 'アーキテクチャ')
            catalog = json.loads((root / 'catalog.json').read_text())
            document = catalog['documents'][0]
            self.assertEqual(document['tags'], ['architecture'])
            self.assertTrue((root / document['path']).exists())
            html = (root / 'index.html').read_text()
            self.assertIn('検索できる本文', html)
            self.assertNotIn('hiddenStyle', html)
            self.assertNotIn('</script><script>alert(1)</script>', html)
            run(*arguments, '--tag', '設計')
            self.assertEqual(len(json.loads((root / 'catalog.json').read_text())['documents']), 1)
            source.unlink()
            run('build')
            run('tag-rename', 'architecture', 'システム設計')
            renamed = json.loads((root / 'catalog.json').read_text())
            self.assertEqual(library.resolve(renamed, '設計')['label'], 'システム設計')
            self.assertTrue((root / 'catalog.previous.json').exists())

    def test_repository_tag_is_added_and_survives_retagging(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / 'archive'
            source = Path(temporary) / 'note.html'
            source.write_text('<p>資料</p>')
            def run(*args):
                subprocess.run([sys.executable, str(SCRIPT), '--root', str(root), *args], check=True, capture_output=True)
            run('init')
            run('tag-add', 'design', '設計', '--description', '設計の資料')
            run('add', str(source), '--title', '設計', '--summary', '要点', '--project', 'owner/product', '--repository', 'owner/product', '--tag', 'design')
            catalog = json.loads((root / 'catalog.json').read_text())
            document = catalog['documents'][0]
            repository_id = library.resolve(catalog, 'product')['id']
            self.assertEqual(document['tags'], ['design', repository_id])
            run('retag', document['id'], 'design')
            updated = json.loads((root / 'catalog.json').read_text())
            self.assertEqual(updated['documents'][0]['tags'], ['design', repository_id])

    def test_reference_url_encodes_filename(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / '図 #1.html'
            source.write_text('<p>原本</p>')
            catalog = {'tags': [], 'documents': [{'path': str(source)}]}
            library.build(root, catalog)
            self.assertIn('%23', (root / 'index.html').read_text())


if __name__ == '__main__':
    unittest.main()
