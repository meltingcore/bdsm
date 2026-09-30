import contextlib
import io
from pathlib import Path
import tempfile
import unittest

from import_saved_variables import LuaTableParser, ParseError, main, table_bounds


DUNGEON = '''local _, addon = ...
addon.dungeons[2515] = {
    name = "Example",
    warningTriggers = { encounterStart = { [100] = 2 } },
    steps = {
        { number = 1, mapID = 1, title = "Start", roles = { TANK = "Old" } },
        { number = 2, mapID = 1, journalEncounterID = 200, title = "Boss" },
    },
}
'''
SAVE = r'''BDSMDB = {
    showMap = false,
    tipOverrides = { [2515] = { [1] = { title = "Changed", roles = { TANK = "New\nline" } } } },
    customSteps = { [2515] = { { customID = 1, after = "b1", mapID = 1,
                               x = 0.4, title = "A \\"quote\\"" } } },
    routeOrder = { [2515] = { "b1", "c1", "b2" } },
}'''.replace(r'\\"', r'\"')


class ImportTests(unittest.TestCase):
    def test_direct_import_and_repeat(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / 'Data').mkdir()
            dungeon = repo / 'Data' / 'AzureVault.lua'
            dungeon.write_text(DUNGEON)
            save = repo / 'bdsm.lua'
            save.write_text(SAVE)
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(main(['--source', str(save), '--repo', str(repo), '--check']), 1)
                self.assertEqual(main(['--source', str(save), '--repo', str(repo)]), 0)
                first_mtime = dungeon.stat().st_mtime_ns
                self.assertEqual(main(['--source', str(save), '--repo', str(repo), '--check']), 0)
                self.assertEqual(main(['--source', str(save), '--repo', str(repo)]), 0)
            self.assertEqual(dungeon.stat().st_mtime_ns, first_mtime)
            result = dungeon.read_text()
            self.assertIn('importRevision = ', result)
            self.assertNotIn('showMap', result)
            self.assertIn('[100] = 3', result)
            start, end = table_bounds(result, r'\bsteps\s*=\s*\{')
            parsed = LuaTableParser(result[start:end]).value()
            self.assertEqual([parsed[i]['number'] for i in range(1, 4)], [1, 2, 3])
            self.assertEqual(parsed[1]['title'], 'Changed')
            self.assertEqual(parsed[1]['roles']['TANK'], 'New\nline')
            self.assertEqual(parsed[2]['title'], 'A "quote"')
            self.assertEqual(parsed[3]['title'], 'Boss')

    def test_rejects_executable_saved_file(self):
        with self.assertRaises(ParseError):
            LuaTableParser('BDSMDB = {}\nos.execute("unexpected")').document()

    def test_preserves_escaped_utf8_bytes(self):
        from import_saved_variables import quote_lua
        parsed = LuaTableParser(r'BDSMDB = { tip = "\195\169" }').document()
        self.assertEqual(quote_lua(parsed['tip']), r'"\195\169"')


if __name__ == '__main__':
    unittest.main()
