# Projeto-Cloud

## Rodando o projeto

O primeiro passo para rodar o programa é instalar o terraform na sua máquina. Um tutorial para o seu sistema operacional pode ser encontrado no link https://developer.hashicorp.com/terraform/install.

O segundo passo é instalar a cli da AWS. Instruções de instalação podem ser encontradas nesta pagina web https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#cliv2-linux-install

Com isso, logue suas credênciais na CLI da aws, usando as seguintes variáveis de ambiente:
<code>
export AWS_ACCESS_KEY_ID=YOURACCESSKEYID
export AWS_SECRET_ACCESS_KEY=YOURSECRETACESSKEY
export AWS_DEFAULT_REGION=us-east-1
</code>

Então, crie uma chave ssh na sua pasta ~/.ssh com o nome instancekp. Caso queira usar outro nome para a chave, basta trocar o caminho do arquivo na linha 152 para o nome desejado.
A chave pode ser criada com o seguinte comando:
<code>
ssh-keygen
</code>

Em seguida, após instalar o projeto na sua máquina e entrar nele, rode os seguintes comando:

<code>
terraform init
terraform apply
</code>

Com apenas esses comando, o programa pedirá para que você infome alguns parâmetrs pela linha de comando. Para evitar isso, crie um arquivo secrets.tfvars (recomendado que em um diretório separado *QUE NÃO SEJA UM REPOSITÓRIO GIT*, para evitar a possibilidade de vazamento das suas credênciais). Segue um exemplo desse arquivo

<code>
db_username = "myusername"
db_password = "mypassword"
my_ip = "0.0.0.0"
</code>

Com um arquivo assim, o comando apropriado é
<code>
terraform apply -var-file="../secrets.tfvars"
</code>

## VPC
Para ter toda a infraestrutura seguinte, foi criada uma VPC onde todos os componentes existem.
## Subnets
Para garantir a privacidade da nossa base de dados, e acessibilidade ao load balancer, e consequentemente, nossas instâncias, foram criadas 2 redes públicas e duas redes privadas. Enquanto as redes públicas tem os blocos de CIDR <code>10.0.1.0/24</code> e <code>10.0.2.0/24</code>, as redes privadas ocupam os blocos CIDR<code>10.0.101.0/24</code> e <code>10.0.102.0/24</code>



