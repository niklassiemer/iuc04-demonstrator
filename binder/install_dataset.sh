
echo 'curl finished; current workspace:'
ls -lrt

echo 'untar'
tar -xvf dpd_data.tar.gz
rm dpd_data.tar.gz

echo 'untar finished, current workspace:'
echo 'pwd' $(pwd)
ls -lrt

cd ..

echo 'run python to unpack from '
echo 'pwd=' $(pwd)
ls -lrt

python << EOF
import os
from pyiron_base import Project
import shutil
import tarfile
pr = Project('.')
print(f'project to operate on: {pr} content: {pr.list_all()}')
for project in os.listdir('DPD_data'):
    w_pr = Project('wdir')
    if not project.endswith('.tar.gz'):
        continue
    print(f'Working on: {project}')
    name = project[:-12]
    
    print(f'file: {project} content: {pr.list_all()}')
    shutil.copy2(os.path.join('DPD_data', project), os.path.join(w_pr.path, project))
    with tarfile.open(os.path.join(w_pr.path, project)) as f:
        f.extractall(w_pr.path)
    shutil.copy2(os.path.join('DPD_data', f"{name}_export.csv"), os.path.join(w_pr.path, 'export.csv'))
    
    print(f'file: {project} content after copy: {pr.list_all()}')
    pr.open(name).unpack(w_pr.path)
    shutil.rmtree('wdir')

# fix pyiron tables looking for the analysis project

print('now fix paths for pyiron table')

from pyiron_base import ProjectHDFio
pr_tables = Project('pr_tables/S7_GB_tables')
for node in pr_tables.list_nodes():
    input_hdf = ProjectHDFio(pr_tables, pr_tables.path + f'/{node}.h5', h5_path=node+'/input')
    if 'project' in input_hdf.list_nodes():
        del input_hdf['project']

EOF

