# README

# Crear un nuevo proyecto desde este repositorio base

Este repositorio está pensado para ser usado como **base de nuevos proyectos**.  
Cada nuevo proyecto que nazca desde aquí debe poder:

- comenzar con una base estándar
- tener su propio desarrollo independiente
- seguir recibiendo mejoras futuras desde este repositorio base

Para lograrlo, el flujo oficial es:

- el proyecto nuevo se crea como **repositorio independiente**
- este repositorio base se configura como remoto `upstream`
- el proyecto nuevo usa su propio `origin`
- cuando existan mejoras en la base, el proyecto nuevo puede traerlas desde `upstream`

---

## Uso de este repositorio

Este repositorio es una base para nuevos proyectos.  
Los proyectos derivados deben crearse como repositorios independientes y mantener este repositorio configurado como `upstream` para poder recibir mejoras futuras.

---

## Política de proyectos derivados

Todo proyecto que nazca desde este repositorio debe:

- crear su propio repositorio independiente
- configurar este repositorio como `upstream`
- realizar su desarrollo sobre `origin`
- sincronizar periódicamente cambios desde `upstream`

---

## Conceptos clave

- **origin**: repositorio del proyecto nuevo
- **upstream**: repositorio base del cual nació el proyecto

### Ejemplo

- `origin` → `git@github.com:empresa/proyecto-cliente-a.git`
- `upstream` → `git@github.com:empresa/dashboard-base.git`

---

## Flujo oficial para crear un nuevo proyecto

### 1. Crear el nuevo repositorio en GitHub
Crear manualmente en GitHub un repositorio nuevo para el proyecto.

```bash
git@github.com:empresa/proyecto-cliente-a.git
```
***Este repositorio debe estar vacío al inicio.***


### 2. Crear carpeta en local y setear origin

```bash
mkdir new-project
cd /new-project
git init
git checkout main
git remote add origin git@github.com:Samubz/admin_base.git
git pull origin main
```

### 3. Cambiar la configuración de remotos
Renombrar el remoto actual para que el repositorio base quede como upstream:
```bash
git remote rename origin upstream
```
Agregar el repositorio nuevo como origin:
```bash
git remote add origin git@github.com:Samubz/new-peoject.git
```


### 4. Verificar remotos
```bash
git remote -v
```
Debería verse algo similar a esto:
```bash
origin	git@github.com:Samubz/fidelidade_admin.git (fetch)
origin	git@github.com:Samubz/fidelidade_admin.git (push)
upstream	git@github.com:Samubz/admin_base.git (fetch)
upstream	git@github.com:Samubz/admin_base.git (push)
```

### 5. Subir el proyecto nuevo a su propio repositorio
```bash
git push -u origin main
```
Si la rama principal del proyecto usa master o develop, reemplazar main por la correspondiente.

## Flujo de trabajo diario del proyecto nuevo

A partir de este punto:
- todo el desarrollo del proyecto se hace contra origin
- los cambios comunes del dashboard base se traen desde upstream

## Cómo traer cambios nuevos desde el repositorio base

### 1. Obtener cambios del repositorio base
```bash
git fetch upstream
```
### 2. Integrar cambios en la rama principal del proyecto
Si la rama principal es main:
```bash
git checkout main
git merge upstream/main
```
Si usan develop como rama de integración:
```bash
git checkout develop
git merge upstream/main
```
Esto depende de la estrategia de ramas del equipo.

## Ejemplo completo

```bash
git clone git@github.com:empresa/dashboard-base.git proyecto-nuevo
cd proyecto-nuevo

git remote rename origin upstream
git remote add origin git@github.com:empresa/proyecto-nuevo.git

git remote -v

git push -u origin main
```
Cuando existan cambios nuevos en la base:

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```


##Crear un usuario

```bash

bin/rails c

email = 'sambzgo@gmail.com'
password = '123123'

subdomain = 'demo-catalogo-pro'
organization = Organization.find_or_initialize_by(subdomain: subdomain)
organization.assign_attributes(
  name: organization.name.presence || "Bar & Cocina Demo",
  plan: Organization::PLAN_PRO
)
organization.save!

ActsAsTenant.with_tenant(organization) do
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    organization: organization,
    name: user.name.presence || "Admin demo",
    dni: user.dni.presence || "DEMO-1",
    language: user.language.presence || Languages::ES,
    password: password,
    password_confirmation: password
  )
  user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
  user.save!
  user.add_role(:super_admin)
  user.add_role(:tenant_admin, organization) unless user.has_role?(:tenant_admin, organization)
  puts <<~MSG
    Listo.
      Organización: #{organization.name} (#{organization.subdomain}) id=#{organization.id} plan=#{organization.plan}
      Usuario:      #{user.email} (tenant_admin: #{user.tenant_admin?(organization)})
  MSG
end
exit
```

## Para iniciar el proyecto

```bash
bundle install
npm install

foreman start -f Procfile.dev
```

ingresar a 
- http://demo-catalogo-pro.localhost:5100/home