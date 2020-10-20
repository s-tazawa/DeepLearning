## jupyter notebookの起動
    docker exec -it deep_learning bash
    jupyter notebook --port 8000 --ip=0.0.0.0 --allow-root



# kubernetes
## トークンの取得

kubectl -n kube-system describe secret default