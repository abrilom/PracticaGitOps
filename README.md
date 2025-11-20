# Infraestructura AWS con Terraform y Ansible - Alta Disponibilidad
## Descripción
Este proyecto implementa una arquitectura de alta disponibilidad en AWS mediante la integración de Terraform y Ansible. Dicha insfraestructura incluye: 
	- Application Load Balancer (ALB) para balancear el tráfico
	- AutoScaling Group (ASG) con mínimo 2 y máximo 4 instancias EC2 en subredes públicas 
	- Base de datos RDS PostgresSQL en una subred privada
	- Un NAT Gateway para permitir las actualizaciones de la RDS
	- Pipelie de CI/CD con GitHub Actions que automatiza la creación y configuración de la infraestructura

## Requisitos previos
	- Cuenta de AWS con permisos para crear VPC, subnets, ALB, EC2, ASG, RDS y NAT
	- Clave SSH para acceder a las instancias EC2
	- Tener instalado terraform, ansible y sus dependencias
	- Configurar en GitHub Actions los siguientes secretos: 
		- AWS_ACCESS_KEY_ID
		- AWS_SECRET_ACCESS_KEY
		- AWS_REGION
		- EC2_SSH_PRIVATE_KEY

## Estructura del repositorio
.
├── terraform/                  # Código Terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
├── ansible/                    # Playbooks Ansible
│   ├── site.yml
│   ├── roles/
│   └── aws_ec2.yml             # Inventario dinámico
├── .github/
│   └── workflows/
│       └── workflow.yml        # Pipeline CI/CD
└── README.md 

## Pipeline CI/CD
El pipeline de GitHub Actions realiza los siguientes pasos:

	1. Configura el sistema
		- Comprueba que se tienen todas las dependencias instaladas
		- Configura las credenciales de AWS
		- Configura las llaves SSH
 
	2. Valida el código
		- Comprueba la syntaxis (terraform validate, ansible-playbook --syntax-check)

	3. Crea la infraestructura
		- terraform init --> Inicializa terraform
		- terraform plan --> Genera el plan de ejecución
		- terraform apply --> Aplica los cambios del plan en AWS

	4. Configura las instancias EC2
		- ansible-playbook --> Ansible configura las instancias EC2 usando la SSH guardada como secreto

El workflow se ejecuta manualmente usando workflow_dispatch 

## Ejecución manual del workflow
	1. Ve a la pestaña Actions del repositorio de GitHub
	2. Selecciona el workflow Infraestructure CI/CD
	3. Haz click en Run workflow
	4. GitHub Actions ejecutará Terraform y Ansible de manera secuencial








