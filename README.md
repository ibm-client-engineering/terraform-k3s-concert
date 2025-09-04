# terraform-k3s-concert

## Work in progress...

This asset will deploy a k3s cluster to a vmware environment.

The ultimate goal is to automate the installation of IBM Concert.

## Some pre-reqs

Make sure ansible is installed

Also install the requirements:

```tsx
cd ansible
sudo pip3 install -r requirements.txt
```

Also you will need helm installed as well:

```tsx
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
sudo ./get_helm.sh
```

Finally kubectl