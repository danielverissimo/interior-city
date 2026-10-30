import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location('ic_mansions_import',ROOT/'scripts/ic-mansions-import.py')
m=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(m)

class MansionImportTests(unittest.TestCase):
    def fixture(self,source):
        source.mkdir()
        coords={'x':1,'y':2,'z':3}
        row={'id':'fixture','name':'Mansão Sintética','group':'MansaoFixture','permission':'perm.mansaofixture',
             'price':1000000,'iptuValue':10,'maxResidents':2,'voucher':'valemansao1m','purchaseCoords':coords,
             'chest':{'enabled':True,'name':'Mansao_fixture','weight':500,'coords':coords},
             'garage':{'enabled':True,'id':'Mansao_fixture','type':'Publica','blipDistance':5,'coords':coords,'spawnCoords':[dict(coords,w=90)]},
             'doors':[],'ownerId':101,'members':[202],'createdAt':1,'purchasedAt':10,'lastIptuPaidAt':10,'iptuPaidUntil':100,
             'furniture':[dict(coords,id='piece',itemId='chair',model='prop_chair',heading=90,paidPrice=750)]}
        (source/'mansions.json').write_text(json.dumps({'version':1,'mansions':[row]},ensure_ascii=False))
        (source/'furniture_catalog.json').write_text(json.dumps({'version':1,'imageBase':'https://example.invalid/{model}','items':[{'id':'chair','name':'Cadeira','model':'prop_chair','category':'Cadeiras','price':900}]}))

    def test_plan_preserves_source_without_writing(self):
        with tempfile.TemporaryDirectory()as tmp:
            root=Path(tmp).resolve();source=root/'legacy';out=root/'own';self.fixture(source)
            before=(source/'mansions.json').read_bytes()
            report=m.prepare(source,out)
            self.assertEqual(report,{'mansions':1,'occupied':1,'residents':2,'furniture':1,'catalogItems':1,'applied':False})
            self.assertFalse(out.exists());self.assertEqual((source/'mansions.json').read_bytes(),before)

    @unittest.skipUnless(shutil.which('lua'),'Lua unavailable')
    def test_private_import_is_accepted_by_actual_store_and_does_not_renew_tax(self):
        with tempfile.TemporaryDirectory()as tmp:
            root=Path(tmp).resolve();source=root/'legacy';out=root/'own';self.fixture(source)
            with self.assertRaises(m.ImportError):m.prepare(source,out,apply=True)
            self.assertFalse(out.exists())
            self.assertTrue(m.prepare(source,out,apply=True,writers_stopped=True)['applied'])
            self.assertTrue(m.verify(out)['verified'])
            self.assertEqual((out/'state-a.json').stat().st_mode&0o777,0o600)
            self.assertEqual(out.stat().st_mode&0o777,0o700)
            self.assertNotIn('imageBase',json.loads((out/'catalog.json').read_text()))
            run=subprocess.run(['lua',str(ROOT/'tests/ic_mansions_import.lua'),str(ROOT),str(out)],capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stdout+run.stderr)
            with self.assertRaises(m.ImportError):m.verify(out)
            with self.assertRaises(m.ImportError):m.prepare(source,out,apply=True,writers_stopped=True)

    def test_refuses_invalid_financial_or_dependent_state_and_links(self):
        for defect in ('paidPrice','spawns','members','symlink'):
            with self.subTest(defect=defect),tempfile.TemporaryDirectory()as tmp:
                root=Path(tmp).resolve();source=root/'legacy';out=root/'own';self.fixture(source)
                path=source/'mansions.json';document=json.loads(path.read_text());row=document['mansions'][0]
                if defect=='paidPrice':del row['furniture'][0]['paidPrice']
                elif defect=='spawns':row['garage']['spawnCoords']=[]
                elif defect=='members':row['members']=[101]
                if defect=='symlink':
                    other=root/'real.json';path.rename(other);path.symlink_to(other)
                else:path.write_text(json.dumps(document))
                with self.assertRaises(m.ImportError):m.prepare(source,out,apply=True,writers_stopped=True)
                self.assertFalse(out.exists())
