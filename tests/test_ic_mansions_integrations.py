from pathlib import Path
import shutil
import re
import subprocess
import unittest

ROOT=Path(__file__).resolve().parents[1]

class MansionIntegrationTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('lua'),'Lua unavailable')
    def test_actual_inventory_and_garage_gates(self):
        result=subprocess.run(['lua',str(ROOT/'tests/ic_mansions_integrations.lua'),str(ROOT)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    @unittest.skipUnless(shutil.which('luac'),'Lua compiler unavailable')
    def test_modified_game_resource_syntax(self):
        paths=['resources/[scriptcore]/inventory/server/modules/chest.lua',
               'resources/[scriptcore]/m_garage/server-side/functions.lua',
               'resources/[scriptcore]/dm_spawn/server/server.lua',
               'resources/[scripts]/doorsv2/doors_client.lua','resources/[scripts]/doorsv2/doors_server.lua',
               'resources/[vrp]/vrp/base.lua','resources/[vrp]/vrp/server-side/group.lua',
               'resources/[scripts]/m_orgs_v2/server/00_dynamic_orgs.lua']
        for path in paths:
            with self.subTest(path=path):
                source=(ROOT/path).read_text()
                # The supplied inventory has +=/-= and optional-member syntax.
                # Lower these in-memory for stock-luac syntax QA only; this does
                # not claim native runtime validation of the pre-existing DSL.
                source=re.sub(r'(\b[A-Za-z_]\w*(?:\[[^\]\n]+\]|\.\w+)*)\s*([+\-])=\s*',
                              lambda match:f'{match[1]} = {match[1]} {match[2]} ',source)
                source=source.replace('?.','.')
                result=subprocess.run(['luac','-p','-'],input=source,capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr)
