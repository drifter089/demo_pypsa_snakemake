
INPUT_FILE=$1
OUTPUT_FILE=$2
RULE_NAME=$3

INPUT_DIR_NAME=$(dirname "$INPUT_FILE")
OUTPUT_DIR_NAME=$(dirname "$OUTPUT_FILE")

echo "input dir: $INPUT_DIR_NAME"
echo "output dir: $OUTPUT_DIR_NAME"
echo "rule name: $RULE_NAME"

echo creating your VM....
gcloud compute instances create labrat \
    --project=stately-forest-407206 \
    --zone=us-west4-b \
    --machine-type=e2-standard-2 \
    --tags=http-server,https-server \
    --image-project=debian-cloud \
    --image-family=debian-10 \
    --metadata=enable-guest-attributes=TRUE \
    --metadata-from-file=startup-script=vm_config.sh
    #  --container-image=akshatmittaloet/demo-pypsa \
    # --container-restart-policy=always \
    # https://cloud.google.com/compute/docs/containers/configuring-options-to-run-containers

until gcloud compute instances get-guest-attributes labrat \
    --zone=us-west4-b \
    --query-path=vm/ready > /dev/null 2>&1
do
    sleep 5 && echo waiting for VM to boot...
done


gcloud compute ssh labrat \
    --command='sudo docker run hello-world'  \
    --zone=us-west4-b 

gcloud compute ssh labrat \
    --command='sudo git clone https://github.com/drifter089/demo_pypsa_snakemake.git'  \
    --zone=us-west4-b 

gcloud compute ssh labrat \
    --command='sudo docker build -t demo-pypsa ./demo_pypsa_snakemake/'  \
    --zone=us-west4-b 

gcloud compute ssh labrat \
    --command='sudo docker images'  \
    --zone=us-west4-b 


# ~/ls = demo_pypsa_snakemake  input  results prepared_networks

gcloud compute scp --recurse "$(pwd)"/$INPUT_DIR_NAME/ labrat:~/$INPUT_DIR_NAME/ --zone=us-west4-b

SNAKEMAKE_COMMAND="snakemake --cores 1 $RULE_NAME"
DOCKER_COMMAND="sudo docker run -v ~/$INPUT_DIR_NAME/:/$INPUT_DIR_NAME/ -v ~/$OUTPUT_DIR_NAME:/$OUTPUT_DIR_NAME --entrypoint /bin/bash demo-pypsa -c '$SNAKEMAKE_COMMAND'"

gcloud compute ssh labrat \
    --command="$DOCKER_COMMAND"  \
    --zone=us-west4-b 

gcloud compute scp --recurse labrat:~/$OUTPUT_DIR_NAME/ \
    "$(pwd)"/ \
    --zone=us-west4-b


echo deleting VM this will take a while.....
gcloud compute instances delete labrat --zone=us-west4-b --quiet

####### VM ########

# this solution can be improved by directly uploading the files to bucket
# using prebuilt image or use docker to pull the image 

####### k8 ##########

# in k8 solution we will upload data directly to buckets 
# then use buckets as persistent volume claims
# https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver
# write a k8 file that creates a container each for prepared_networks
# create different images for prepare network and solve network
# maybe make a persistent disk that attaches to the prepare network pod that have the data we download from sendo already attached.