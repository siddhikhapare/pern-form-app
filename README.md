# Highly Available Three-Tier Web Application Architecture on AWS

A complete, step-by-step walkthrough for deploying a **PERN stack (PostgreSQL, Express, React/Next.js, Node.js)** form-builder application on AWS using a highly available, secure, auto-scaling 3-tier architecture.


![final output](https://github.com/siddhikhapare/images-for-doc/blob/main/final-formapp.PNG)

<br><br>

![create-form](https://github.com/siddhikhapare/images-for-doc/blob/main/create-form.PNG)



### Architecture Layers

1. **Presentation Tier (Web Layer)**: ReactJS + Nginx
2. **Application Tier (Logic Layer)**: Node.js + Express.js + PM2
3. **Data Tier (Database Layer)**: Amazon RDS PostgreSQL Multi-AZ

### Request flow

1. A user opens `https://demo.siddhikapphub.org`.
2. **Route 53** resolves the name through an Alias A record to **CloudFront**.
3. **CloudFront** terminates TLS (ACM certificate) and forwards to the **external ALB** over HTTP.
4. The ALB distributes traffic to **Nginx** instances in the Web-tier Auto Scaling Group.
5. Nginx serves the static frontend build and proxies API calls to the **internal ALB**.
6. The internal ALB routes to **Node.js (PM2)** instances on port `5000` in private subnets.
7. The backend queries **RDS PostgreSQL** in isolated DB subnets on port `5432`.

---


## 🔧 Infrastructure Components

| Component | Service | Configuration | Purpose |
|-----------|---------|---------------|---------|
| **VPC** | Amazon VPC | CIDR: 192.168.0.0/16 | Network isolation |
| **Subnets** | Public/Private | 6 subnets across 2 AZs | Multi-AZ deployment |
| **Internet Gateway** | IGW | 1 per VPC | Internet access for public subnets |
| **NAT Gateway** | NAT-GW | 2 (one per AZ) | Outbound internet for private subnets |
| **Bastion Host** | EC2 | t3.micro | Secure SSH access |
| **Web Tier** | EC2 + ASG | t3.small, Min: 2, Max: 6 | ReactJS frontend |
| **App Tier** | EC2 + ASG | t3.medium, Min: 2, Max: 8 | Node.js backend |
| **External ALB** | Application LB | Internet-facing | Web tier load balancing |
| **Internal ALB** | Application LB | Internal | App tier load balancing |
| **Database** | RDS PostgreSQL | db.m5.large, Multi-AZ | Data persistence |
| **DNS** | Route 53 | Hosted Zone | Domain management |
| **CDN** | CloudFront | Global distribution | Content delivery |
| **SSL/TLS** | ACM | Free certificates | HTTPS encryption |
| **Notifications** | SNS | Email alerts | Scaling event monitoring |

---


## 🌐 Network Architecture

### VPC CIDR Block
```
VPC: 192.168.0.0/16
```

### Subnet Design

#### Availability Zone 1 (ap-south-1a)

| Subnet Type | Name | CIDR | Components |
|-------------|------|------|------------|
| Public | public-subnet-1 | 192.168.1.0/24 | Bastion, Web Tier EC2, NAT-GW |
| Private | private-subnet-1 | 192.168.11.0/24 | App Tier EC2, Internal ALB |
| Database | db-private-1 | 192.168.21.0/24 | RDS Primary |


#### Availability Zone 2 (ap-south-1b)

| Subnet Type | Name | CIDR | Components |
|-------------|------|------|------------|
| Public | public-subnet-2 | 192.168.2.0/24 | Web Tier EC2, NAT-GW |
| Private | private-subnet-2 | 192.168.12.0/24 | App Tier EC2, Internal ALB |
| Database | db-private-2 | 192.168.22.0/24 | RDS Standby |

### Route Tables

#### Public Route Table
```
Destination         Target
192.168.0.0/16     local
0.0.0.0/0          igw-xxxxxx (Internet Gateway)
```

**Associated Subnets**: public-subnet-1, public-subnet-2

#### Private Route Table (for App Tier)
```
Destination         Target
192.168.0.0/16     local
0.0.0.0/0          nat-xxxxxx (NAT Gateway)
```
**Associated Subnets**: private-subnet-1, private-subnet-2

#### Database Route Table
```
Destination         Target
192.168.0.0/16     local
```
**Associated Subnets**: db-private-1, db-private-2

---

## 🔒 Security Groups Configuration
| Tier | Security Group | Protocol | Port | Source | Description |
|------|----------------|----------|------|---------|-------------|
| Bastion Tier | `Bastion-host-sg` | TCP (SSH) | 22 | `0.0.0.0/0` | SSH access for administrators *(Production: restrict to trusted IPs)* |
| Web Tier | `External-load-balancer-sg` | TCP (HTTP) | 80 | `0.0.0.0/0` | Public web traffic from CloudFront |
| Web Tier | `Web-tier-EC2-sg` | TCP (SSH) | 22 | `Bastion-host-sg` | SSH access from Bastion Host |
| Web Tier | `Web-tier-EC2-sg` | TCP (HTTP) | 80 | `External-load-balancer-sg` | Traffic from External Load Balancer |
| Application Tier | `Internal-load-balancer-sg` | TCP (HTTP) | 80 | `Web-tier-EC2-sg` | API requests from Web Tier |
| Application Tier | `App-tier-EC2-sg` | TCP (SSH) | 22 | `Bastion-host-sg` | SSH access from Bastion Host |
| Application Tier | `App-tier-EC2-sg` | TCP | 5000 | `Internal-load-balancer-sg` | Application traffic to Node.js service |
| Database Tier | `Database-tier-sg` | TCP (PostgreSQL) | 5432 | `App-tier-EC2-sg` | Database access from Application Tier |
| Database Tier | `Database-tier-sg` | TCP (PostgreSQL) | 5432 | `Bastion-host-sg` | Administrative database access |

---

## Prerequisites

- An AWS account with permissions for EC2, VPC, RDS, ELB, Auto Scaling, CloudWatch, SNS, ACM, CloudFront and Route 53
- A registered domain (GoDaddy, Squarespace, Namecheap, Route 53, etc.)
- An EC2 key pair (this guide uses `asg-threetierapp-key`) and the `.pem` file saved locally
- Local tools: `ssh`, `ssh-add`, [pgAdmin 4](https://www.pgadmin.org/) (or `psql`)
- The application source code: [pern-form-app](https://github.com/siddhikhapare/pern-form-app) (`frontend/`, `backend/`, `db.sql`, `finalnginx.conf`)

---

## Recommended Build Order

Some resources depend on others (for example, Nginx needs the **internal ALB DNS name**, and AMIs must be created from an already-configured server). Follow this order to avoid rework:

1. VPC, subnets, IGW, NAT, route tables
2. Security groups
3. Create Bastion host 
4. RDS and database initialization
5. Configure the **App tier** template instance (Node.js + PM2)
6. Create target groups and both load balancers 
7. Configure the **Web tier** template instance (Nginx + frontend) using the internal ALB DNS
8. Create AMIs and launch templates
9. Create Auto Scaling Groups, SNS and scaling policy
10. ACM certificate, CloudFront, Route 53
11. Test and validate

---

## Deployment Guide - 

### Step 1. Connect through the Bastion with SSH agent forwarding - 

On your **local machine**:

```bash
# Load the key into the SSH agent
ssh-add your-app-key.pem

# Verify it is loaded
ssh-add -l

# Connect to the bastion (-A forwards the agent, so the .pem never leaves your laptop)
ssh -A ubuntu@<bastion-public-ip>
```

From the **bastion**:

```bash
ssh ubuntu@<web-tier-private-ip>
# or
ssh ubuntu@<app-tier-private-ip>
```
---
## Step 2: App Tier Configuration (Node.js + PM2)

SSH to `App-server-a` through the bastion, then run the following.

### 2.1 Install Git and clone

```bash
sudo apt update
sudo apt install git -y
git clone https://github.com/siddhikhapare/pern-form-app.git
```

### 2.2 Install Node.js

```bash
sudo snap install node --classic --channel=20/stable
node --version
npm --version

# Optional: nvm for switching Node versions
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source ~/.bashrc
nvm --version
```

### 2.3 Install backend dependencies

```bash
cd pern-form-app/backend/
npm i
```

### 2.4 Configure environment variables

Create `backend/.env` (variable names must match what `server.js` reads; adjust to your repo):

```env
PORT=5000
NODE_ENV=production
DB_HOST=<rds-endpoint>
DB_PORT=5432
DB_NAME=formbuilder
DB_USER=formappuser
DB_PASSWORD=<STRONG_PASSWORD>
```

> Add `.env` to `.gitignore`. For a stronger setup, load secrets from **AWS Secrets Manager** or **SSM Parameter Store** using an instance IAM role.

### 2.5 Install and configure PM2

```bash
sudo npm i -g pm2
touch ecosystem.config.js
```

Example `ecosystem.config.js`:

```js
module.exports = {
  apps: [{
      name: 'backend',
      script: './server.js',
      instances: "max",
      exec_mode: 'cluster',
      //autorestart: true,
      autorestart: false,  
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      error_file: './logs/errors.log',
      out_file: './logs/out.log',
      log_file: './logs/appcombined.log',
      time: true
    }]
};
```

### 2.6 Start the app

```bash
mkdir -p logs
pm2 start ecosystem.config.js     # or: pm2 start server.js
pm2 list
pm2 logs
```

### 2.7 Start on boot

```bash
pm2 startup
# PM2 prints a command. Copy and run it, for example:
sudo env PATH=$PATH:/snap/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Freeze the current process list so it is restored after reboot
pm2 save
```

### 2.8 Useful PM2 commands

| Command | Purpose |
|---|---|
| `pm2 list` | List processes |
| `pm2 logs` | Tail logs |
| `pm2 monit` | Real-time dashboard |
| `pm2 describe <id\|name>` | Detailed process info |
| `pm2 restart <name>` | Restart |
| `pm2 report` | Diagnostic report |

**Reset and recreate from scratch**

```bash
pm2 unstartup
pm2 delete all
pm2 flush
pm2 save --force
```
---

## Step 3: Web Tier Configuration (Nginx + Frontend)

SSH to `Web-server-a` through the bastion.

### 3.1 Install tools

```bash
sudo apt update
sudo apt install git nginx -y
git clone https://github.com/siddhikhapare/pern-form-app.git

sudo snap install node --classic --channel=20/stable
node --version && npm --version
```

### 3.2 Build the frontend

```bash
cd pern-form-app/frontend/
npm i
# Update any environment variables (API base URL, etc.) before building
#NEXT_PUBLIC_API_URL=https://your-domain.com/api
npm run build
```

The build produces an `out/` directory of static files.

### 3.3 Publish the build for Nginx

```bash
sudo mkdir -p /var/www/pern-form-app
sudo cp -r /home/ubuntu/pern-form-app/frontend/out /var/www/pern-form-app/
sudo chown -R www-data:www-data /var/www/pern-form-app
sudo chmod -R 755 /var/www/pern-form-app
```

### 3.4 Configure Nginx

Use the repo's [`finalnginx.conf`](https://github.com/siddhikhapare/pern-form-app/blob/main/finalnginx.conf), and set:

- the **internal ALB DNS name** as the API upstream
- your **domain name** as `server_name`

Navigate to /etc/nginx/sites-available/default and add the complete Nginx configuration provided in finalnginx.conf to this default named file.

```bash
sudo nano /etc/nginx/sites-available/default     # or the file you created
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
```

Expected: `syntax is ok` and `test is successful`.

---

## Step 4: Database Tier (RDS PostgreSQL)

### 4.1 Reach the database through the Bastion (SSH tunnel)

The database is private, so use the bastion as a jump point.

**Option A: pgAdmin with SSH tunnel**

*Connection tab*

| Field | Value |
|---|---|
| Host name/address | `<rds-endpoint>` (e.g. `formappdb.xxxx.ap-south-1.rds.amazonaws.com`) |
| Port | `5432` |
| Maintenance database | `formbuilder` |
| Username | `formappuser` |
| Password | your DB password |

*SSH Tunnel tab*

| Field | Value |
|---|---|
| Use SSH tunneling | On |
| Tunnel host | Bastion public DNS |
| Tunnel port | `22` |
| Username | `ubuntu` |
| Authentication | Identity file |
| Identity file | path to your `.pem` |


### 4.2 Create the application user and database

From the bastion (install the client first: `sudo apt install postgresql-client -y`):

```bash
psql -h <rds-endpoint> -U postgres
```

```sql
-- Use a strong, unique password. Never commit real credentials to Git.
CREATE USER formappuser WITH PASSWORD '<STRONG_PASSWORD>';
CREATE DATABASE formbuilder OWNER formappuser;
GRANT ALL PRIVILEGES ON DATABASE formbuilder TO formappuser;

-- Connect to the new DB, then grant schema rights
\c formbuilder
GRANT ALL ON SCHEMA public TO formappuser;
\l
```
### 4.3 Verify

```bash
psql -h <rds-endpoint> -U formappuser -d formbuilder
```

```sql
SELECT * FROM forms;
SELECT * FROM form_responses;
SELECT * FROM response_data;
```
---


## Step 5: ACM, CloudFront and Route 53
### 5.1 Route 53 hosted zones and NS delegation

This project uses a root domain managed at an external registrar and a **delegated subdomain** hosted in Route 53.

1. **Create a public hosted zone** for the subdomain `demo.siddhikapphub.org`. Route 53 auto-creates NS and SOA records.
2. Copy the **four NS values** of the subdomain hosted zone.
3. Delegate the subdomain in the parent DNS:
   - If the parent zone is in Route 53: add an **NS record** named `demo` with those four values.
   - If the parent zone is at an external registrar: add an NS record for `demo` at the registrar's DNS panel (or, to hand the *whole* domain to Route 53, change the registrar's **Nameservers** to the ones from the root hosted zone).

Resolution path for `demo.siddhikapphub.org`: root domain -> NS delegation -> subdomain hosted zone in Route 53 -> Alias A record -> CloudFront.

### 5.2 ACM certificate (must be in `us-east-1`)

CloudFront only accepts certificates from **N. Virginia (`us-east-1`)**.

1. Switch region to **US East (N. Virginia)**
2. **ACM -> Request certificate -> Public**
3. Domain name: `demo.siddhikapphub.org`
4. Validation: **DNS validation**
5. Click **Create records in Route 53** (adds the validation CNAME to the subdomain hosted zone)
6. Wait for status **Issued**

### 5.3 Point the domain at CloudFront
In the subdomain hosted zone, create an Alias A record that maps the apex of the subdomain to the CloudFront distribution (CDN).
**Final record set for the subdomain zone (4 records):** NS, SOA, Alias A (CloudFront), and the ACM validation CNAME. The **root zone has 3 records**, including the NS delegation record for the subdomain.



