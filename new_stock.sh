#!/bin/bash

#=======================#
# Paths
#=======================#

LOG_LOCATION="/nesi/nobackup/aut02787/"
SCRIPT_LOCATION="/nesi/project/aut02787/scripts"

#=======================#
# Workflow Stages
#=======================#

stage_definition(){
    stage "AutomateRun"
    stage "ReConstructLOBAsk"
    stage "ReConstructLOBBid"
    stage "SignedDvolBuy"
    stage "SignedDvolSell"
}

#=======================#

stage(){

    mkdir -pv "$PWD/$STOCKNAME/${1}"
    
    submit_script="$PWD/$STOCKNAME/${1}/${1}_submit.sh"
    collect_script="$PWD/$STOCKNAME/${1}/${1}_collect.sh"

    root_output_dir="${PWD}/${STOCKNAME}/${1}/mat_files/"  


    cat <<submitEOF > ${submit_script}

#!/bin/bash -e

# Resources
#===========================================================#
stock_suffix="${1}"
stock_name="${STOCKNAME}"                                 
time="04:00:00"
mem="5000"
rows="${INPUT_ROWS}" # out of ${INPUT_ROWS}

mail_user="none"

# Set Paths
#===========================================================#
root_dir="/nesi/nobackup/aut02787/"     
main_input_mat="${STOCKPATH}"     
root_log_dir="${LOG_LOCATION}/${STOCKNAME}/"

# Validate
#============================================================#
if [ ! -f  "\${main_input_mat}" ]; then
    echo "\${main_input_mat} does not exist! Check that previous jobs ran and paths are correctly set.".
    exit 1
fi
mkdir -pv \$root_log_dir ${root_output_dir}

count=0

for (( i=1; i<=\${rows}; i++ )); do
    if ls ${root_output_dir}*-\${i}.mat 1> /dev/null 2>&1; then
        printf "Row \${i} output already exists, skipping...\r"
    else
        printf "Row \${i} output does not exist, being added to job...\r"
        input_array="\${input_array}\${i},"
        count=\$((count+1))
    fi
done
printf "Job Array containing \${count} jobs being submitted.           \n"

# Submit
#============================================================#
sbatch -t \${time} \
-a \${input_array} \
-J \${stock_name}_\${stock_suffix} \
-o \${root_log_dir}\${stock_name}%a.log \
--mem \${mem} \
--mail-type TIME_LIMIT_80,ARRAY_TASKS \
--mail-user \${mail_user} \
--wrap "module load MATLAB/2018b;\
matlab -nojvm -r \\"addpath('${SCRIPT_LOCATION}');output_mat_\\\${SLURM_ARRAY_TASK_ID}=${1}('\${main_input_mat}',\\\${SLURM_ARRAY_TASK_ID});save('${root_output_dir}/\${stock_name}_${1}-\\\${SLURM_ARRAY_TASK_ID}.mat', 'output_mat_\\\${SLURM_ARRAY_TASK_ID}', '-v7.3');exit;\""
submitEOF
printf  "File '$submit_script' created.\n"

STOCKPATH="$PWD/$STOCKNAME/${1}/${STOCKNAME}.mat"
cat <<collectEOF > ${collect_script}

#!/bin/bash -e


printf "Validating .mat files in '${root_output_dir}'...\n"

for (( i=1; i<=${INPUT_ROWS}; i++ )); do
    if ! \$( ls ${root_output_dir}*-\${i}.mat 1> /dev/null 2>&1 ); then
        printf "'...-\${i}.mat' does not exist! Aborting merge.\n"
        printf "run 'bash ${submit_script}' to generate missing files.\n"
        exit 1
    fi
done
printf "All files present! Merging...\n"

module load MATLAB
matlab -nojvm -r "addpath('${SCRIPT_LOCATION}');merge('$PWD/${STOCKNAME}/${1}/mat_files', '${STOCKPATH}')" 1> /dev/null 2>&1
printf "Merged .mat file created at ${STOCKPATH}"

collectEOF

printf  "File '$collect_script' created.\n"
}

init_stock(){
    # Create Log directory
    mkdir -pv $LOG_LOCATION/$STOCKNAME

    # Count number of rows in input file.
    module load Python
    INPUT_ROWS=$(python -c "import sys,h5py;print(h5py.File(sys.argv[1])['DATA']['DATE'].shape[0])" ${STOCKPATH})
    printf "$INPUT_ROWS rows found.\n"

    stage_definition

    chmod 770 -R $STOCKNAME/*

    printf  "Check resource requirements before running 'submit.sh' scripts!!"
}

read -p "Enter stock name: " STOCKNAME
STOCKNAME=$(echo "$STOCKNAME" | cut -f 1 -d '.')
STOCKPATH="${PWD}/${STOCKNAME}.mat"
while true; do
    if [ -f $STOCKPATH ]; then
        while true; do
            read -p "Is  \"$STOCKPATH\" your input? (y/n) " yn
            case $yn in
                [Yy]* ) 
                    init_stock
                    exit
                    ;;
                [Nn]* ) 
                break
                ;;
                * ) 
                printf "Please answer (y/n), "
                ;;    
            esac
        done
    fi
    read -p "Enter path to stock input:" STOCKPATH
done