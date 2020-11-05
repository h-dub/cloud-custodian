#!/bin/bash
IFS=$'\n\t'
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

sub_id=$(az account show --query id --output tsv)
template_dir="$( cd "$( dirname "$0" )" && pwd )"
var_location='location=westus2'
var_suffix="suffix=${sub_id:${#sub_id} - 12}"

function deploy_resource() {
    echo "Deployment for ${filename_noext} with vars: $var_location $var_suffix started"

    tf_dir=$(dirname $1)
    tf_state="${tf_dir}/terraform.tfstate"
    filename=$(basename $1)
    filename_noext=${filename%.*}

    terraform init $tf_dir
    terraform plan -state $tf_state -var $var_location -var $var_suffix $tf_dir
    terraform apply -state $tf_state -var $var_location -var $var_suffix -auto-approve $tf_dir
    
    echo "Deployment for ${filename_noext} complete"
}

function cleanup_resource() {
    echo "Cleanup for ${filename_noext} with vars: $var_location $var_suffix started"

    tf_dir=$(dirname $1)
    tf_state="${tf_dir}/terraform.tfstate"
    filename=$(basename $1)
    filename_noext=${filename%.*}

    terraform init $tf_dir
    terraform destroy -auto-approve -state $tf_state -var $var_location -var $var_suffix $tf_dir
    
    echo "Cleanup for ${filename_noext} complete"
}

function should_act() {
    if [[ ${act_all} -eq 1 ]]; then
        if ! [[ "${skip_list[@]}" =~ $1 ]]; then
            return 1
        fi
    else
        if [[ "${act_list[@]}" =~ $1 ]]; then
            return 1
        fi
    fi
    return 0
}

function usage {
        echo "Usage: $(basename $0) [-acs] <resources>" 2>&1
        echo '   -a   all resources'
        echo '   -c   cleanup resources. add -a to cleanup all'
        echo '   -s   skip listed'
        echo 'examples:'
        echo 'Deploy all resources               : $(basename $0)'
        echo 'Cleanup all resources              : $(basename $0) -c -a'
        echo 'Deploy only batch                  : $(basename $0) batch'
        echo 'Deploy all resources, except batch : $(basename $0) -s batch'
        echo 'Cleanup all resources, except batch: $(basename $0) -c -s batch'
        
        exit 1
}


act_all=0
cleanup=0
skip=0
optstring="acs"
while getopts ${optstring} arg; do
    case "${arg}" in
        a) act_all=1;;
        c) cleanup=1;;
        s) skip=1;;

        ?)
        echo "Invalid option: -${OPTARG}."
        echo
        usage
        ;;
    esac
done

#args have to be post processed because they rely on OPTIND being fully advanced
if [[ ${#} -eq 0 ]]; then
    #if no args, deploy all resources
   act_all=1
else

    #if skip is enabled, remaining args are the skip list
    if [[ $skip -eq 1 ]]; then
        act_all=1
        skip_list="${@:OPTIND}"
    else
        #if no skip, remaining args are the act list
        if [[ $act_all -eq 0 ]]; then
            act_list="${@:OPTIND}"
        fi
    fi
fi

echo "act_all=${act_all}"
echo "cleanup=${cleanup}"
echo "skip=${skip}"
echo "skip_list=${skip_list}"
echo "act_list=${act_list}"

for file in $(find $template_dir -name "*.tf" -print); do
    filename=${file##*/}
    filename_noext=${filename%.*}
    should_act "$filename_noext"
    if [[ $? -eq 1 ]]; then
        if [[ $cleanup -eq 1 ]]; then
            cleanup_resource ${file} &
        else
            deploy_resource ${file} &
        fi
    fi
done

# Wait until all activities are finished
wait
