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
origin    git@github.com:empresa/proyecto-cliente-a.git (fetch)
origin    git@github.com:empresa/proyecto-cliente-a.git (push)
upstream  git@github.com:empresa/dashboard-base.git (fetch)
upstream  git@github.com:empresa/dashboard-base.git (push)
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
