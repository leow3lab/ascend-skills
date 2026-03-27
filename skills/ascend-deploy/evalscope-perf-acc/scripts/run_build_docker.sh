# #######################################################
#   ⎿  ▐▛███▜▌   
#      ▝▜█████▛▘  Updated：2026.1.22 
#        ▘▘ ▝▝    Author: Yang Jing (aka. WhyJ？)
# #######################################################
# docker load -i /nfs/shared/openlab_dockerhub/arm64/evalscope-arc-bench-20260121.tar 

# ================================
container_name=evalscope-benchmark-cli
image_name=evalscope-arc-bench:20260121
code_path=/nfs2
# ================================

ipc=ipc
network=host
user=root
port=8080
workdir=${code_path}

train_docker_run() {
docker rm -f ${container_name}
docker run -itd -u ${user}  --name ${container_name} \
 --network ${network} \
 --ipc ${network} \
 --privileged=true \
 -p ${port}:${port} \
 -w ${workdir}/nfs/data/agent/evalscope-benchmark \
 --entrypoint /bin/bash \
 -v ${code_path}:${code_path} \
 ${image_name} 
}

set -x
train_docker_run
docker exec -it  ${container_name} /bin/bash