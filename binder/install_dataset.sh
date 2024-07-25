
echo 'curl finished; current workspace:'
ls -lrt

echo 'untar'
tar -xvf dpd_data.tar.gz
rm dpd_data.tar.gz

echo 'untar finished, current workspace:'
ls -lrt

cd ..

echo 'run python to unpack'

python << EOF
import os
from pyiron_base import Project
import shutil
for project in os.listdir('DPD_data'):
    if not project.endswith('.tar.gz'):
        continue
    print(project)
    name = project[:-12]
    shutil.copy2(os.path.join('DPD_data', project), '.')
    shutil.copy2(os.path.join('DPD_data', f"{name}_export.csv"), 'export.csv')
    pr = Project(name)
    pr.unpack(f"{name}_data")
    os.remove(project)
    os.remove('export.csv')

# fix pyiron tables looking for the analysis project

from pyiron_base import ProjectHDFio
pr_tables = Project('pr_tables/S7_GB_tables')
for node in pr_tables.list_nodes():
    input_hdf = ProjectHDFio(pr_tables, pr_tables.path + f'/{node}.h5', h5_path=node+'/input')
    if 'project' in input_hdf.list_nodes():
        del input_hdf['project']

EOF

