import requests
import os
from pyiron_base import Project
import shutil
import tarfile

DPD_data_dir = 'DPD_data'
DPD_tar_file = 'dpd_data.tar.gz'


with requests.get('https://datashare.mpcdf.mpg.de/public.php/webdav/', auth=('8T8WHAo1NLpgAkW', ''), stream=True) as r:
    r.raise_for_status()
    with open(DPD_tar_file, 'wb') as f:
        for chunk in r.iter_content(chunk_size=8192): 
            f.write(chunk)


os.mkdir(DPD_data_dir)
with tarfile.open(DPD_tar_file) as f:
    f.extractall(DPD_data_dir)

os.remove(DPD_tar_file)

pr = Project('.')
for project in os.listdir(DPD_data_dir):
    w_pr = Project('wdir')
    if not project.endswith('.tar.gz'):
        continue
    print(f'Working on: {project}')
    name = project[:-len('_data.tar.gz')]
    
    shutil.copy2(os.path.join(DPD_data_dir, project), os.path.join(w_pr.path, project))
    with tarfile.open(os.path.join(w_pr.path, project)) as f:
        f.extractall(w_pr.path)
    to_copy_pr = w_pr.open(name + '_data')
    shutil.copy2(os.path.join(DPD_data_dir, f"{name}_export.csv"), os.path.join(to_copy_pr.path, 'export.csv'))
    
    pr.open(name).open(to_copy_pr.list_groups()[0]).unpack(w_pr.path)
    shutil.rmtree('wdir')

# fix pyiron tables looking for the analysis project

print('now fix paths for pyiron table')

from pyiron_base import ProjectHDFio
pr_tables = Project('pr_tables/S7_GB_tables')
for node in pr_tables.list_nodes():
    input_hdf = ProjectHDFio(pr_tables, pr_tables.path + f'/{node}.h5', h5_path=node+'/input')
    if 'project' in input_hdf.list_nodes():
        del input_hdf['project']


