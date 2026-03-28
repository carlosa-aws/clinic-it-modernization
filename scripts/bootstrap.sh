#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "Starting EC2 bootstrap..."

dnf update -y
dnf install -y python3 python3-pip git nginx awscli
dnf install -y amazon-cloudwatch-agent

mkdir -p /opt

cd /opt
if [ -d "clinic-it-modernization" ]; then
  cd clinic-it-modernization
  git pull origin main
else
  git clone https://github.com/carlosa-aws/clinic-it-modernization.git
  cd clinic-it-modernization
fi

cd /opt/clinic-it-modernization/app

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

DB_PASSWORD=$(aws ssm get-parameter \
  --name "/${var.project_name}/db/password" \
  --with-decryption \
  --region ${var.aws_region} \
  --query 'Parameter.Value' \
  --output text)

cat > /etc/clinic-app.env <<EOT
DB_HOST=${aws_db_instance.postgres.address}
DB_PORT=5432
DB_NAME=${var.db_name}
DB_USER=${var.db_username}
DB_PASSWORD=$${DB_PASSWORD}
EOT

chown ec2-user:ec2-user /etc/clinic-app.env
chmod 600 /etc/clinic-app.env

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOT
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${var.project_name}-system",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${var.project_name}-nginx-access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "${var.project_name}-nginx-error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "${var.project_name}-user-data",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOT

cat > /etc/systemd/system/clinic-app.service <<EOT
[Unit]
Description=Clinic Intake Flask App
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/clinic-it-modernization/app
EnvironmentFile=/etc/clinic-app.env
ExecStart=/opt/clinic-it-modernization/app/venv/bin/gunicorn --bind 127.0.0.1:5001 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOT

mkdir -p /etc/nginx/conf.d
rm -f /etc/nginx/conf.d/default.conf

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

python3 - <<'PY'
from pathlib import Path

path = Path("/etc/nginx/nginx.conf")
text = path.read_text()

start = text.find("    server {\n        listen       80;")
end = text.find("\n# Settings for a TLS enabled server.")
if start != -1 and end != -1 and start < end:
    text = text[:start] + text[end:]
    path.write_text(text)
PY


cat > /etc/nginx/conf.d/clinic-app.conf <<EOT
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT

systemctl daemon-reload
systemctl enable clinic-app
systemctl start clinic-app

nginx -t
systemctl enable nginx
systemctl restart nginx

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "Bootstrap complete!"