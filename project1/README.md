# End-to-End CI/CD Deployment Using GitHub Actions, Docker Hub & Azure VM

This guide documents **the complete process of deploying a Dockerized application** to an **Azure Ubuntu VM** using **GitHub Actions** and **Docker Hub**.  

Once configured, each code push to your main branch will:
- Build and test the app
- Package it into a Docker image
- Push the image to Docker Hub
- Deploy the container to your Azure VM via SSH

Follow these steps to reproduce the setup anytime.

---

## Prerequisites

1. **Azure Subscription** – To create the virtual machine (VM) and network.
2. **GitHub Account** – For storing source code and configuring GitHub Actions.
3. **Docker Hub Account** – For container image registry.
4. **SSH Key Pair** – For secure access between GitHub Actions and your VM.

---

## ⚙️ Repository Structure

```
Github-Actions/
├─ .github/
│ └─ workflows/
│ └─ ci-cd.yml # CI/CD workflow
├─ Dockerfile
├─ src
│ └─ index.js # Sample Node.js app
├─ package-lock.json
└─ README.md
```

---

## Step 1: Create Docker Hub Account

1. Go to [https://hub.docker.com](https://hub.docker.com)
2. Create a free account
3. Create a new **Access Token** under  
   **Account Settings → Security → New Access Token**

### Example

| Field | Value |
|-------|--------|
| **Access token description** | `github-actions` |
| **Access permissions** | Public Repo Read-only |

Save the generated token safely (used later in GitHub Secrets).

---

## Step 2: Generate SSH Keys

Run the following command on your **local system** to create a dedicated key pair for GitHub Actions deployment:

```bash
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy
```

This creates:

~/.ssh/github_actions_deploy → Private Key

~/.ssh/github_actions_deploy.pub → Public Key

## Step 3: Create Azure Resources
Create VNet, Subnet, NSG, Public IP, NIC and VM

```bash
az network vnet create \
  --resource-group test-rg \
  --name testVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name testSubnet \
  --subnet-prefix 10.0.1.0/24
```

```bash
az network nsg create \
  --resource-group test-rg \
  --name testNSG
```

```bash
az network nsg rule create \
  --resource-group test-rg \
  --nsg-name testNSG \
  --name allow-ssh \
  --protocol tcp \
  --priority 1000 \
  --destination-port-range 22 \
  --access allow
```

```bash
az network public-ip create \
  --resource-group test-rg \
  --name testPublicIP \
  --sku Standard \
  --allocation-method Static
```

```bash
az network nic create \
  --resource-group test-rg \
  --name testNIC \
  --vnet-name testVNet \
  --subnet testSubnet \
  --network-security-group testNSG \
  --public-ip-address testPublicIP
```

```bash
az vm create \
  --resource-group test-rg \
  --name testUbuntuVM \
  --nics testNIC \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B2s
```

```bash
Add GitHub Actions Public Key to VM
az vm user update \
  --resource-group test-rg \
  --name testUbuntuVM \
  --username azureuser \
  --ssh-key-value ~/.ssh/github_actions_deploy.pub
```

## Step 4: Test SSH Access
ssh -i ~/.ssh/github_actions_deploy azureuser@74.225.142.248

ssh azureuser@74.225.142.248

## Step 5: Fix Docker Permission Issue (if any)
```
permission denied while trying to connect to the Docker daemon socket
```

Run the following fix inside your VM:

```bash
sudo snap remove docker

sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker
sudo groupadd -f docker
sudo usermod -aG docker azureuser
exit
```

Then reconnect:
ssh azureuser@74.225.142.248

docker ps   # should work without sudo

## Step 6: Configure GitHub Secrets

In your GitHub repository, go to:

Settings → Secrets and variables → Actions → New repository secret
### GitHub Secrets Configuration

| Secret Name | Description | Example |
|--------------|--------------|----------|
| **DOCKERHUB_USERNAME** | Your Docker Hub username | `sivakumarmahan` |
| **DOCKERHUB_TOKEN** | Docker Hub access token | `abcdefghijklmno` |
| **SERVER_HOST** | Public IP of your Azure VM | `74.225.142.248` |
| **SERVER_USER** | SSH username used to connect to VM | `azureuser` |
| **SSH_PRIVATE_KEY** | Contents of your private SSH key file (`~/.ssh/github_actions_deploy`) | *(Paste full key content here)* |

## Step 7: Allow HTTP Access in NSG

```bash
az network nsg rule create \
  --resource-group test-rg \
  --nsg-name testNSG \
  --name allow-http \
  --protocol tcp \
  --priority 1010 \
  --destination-port-range 80 \
  --access allow
```

## Step 8: Test the Deployment

After your GitHub Actions workflow runs successfully, visit:

azureuser@testUbuntuVM:~$ docker ps

CONTAINER ID   IMAGE                                  COMMAND                  CREATED         STATUS              PORTS                                     NAMES
5505bed72562   sivakumarmahan/github-actions:latest   "docker-entrypoint.s…"   2 minutes ago   Up About a minute   0.0.0.0:80->3000/tcp, [::]:80->3000/tcp   github-actions

azureuser@testUbuntuVM:~$ curl http://localhost

Hello from GitHub Actions CI/CD!

Now, open your browser and visit: http://74.225.142.248 --> You will get "Hello from GitHub Actions CI/CD!"
