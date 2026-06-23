# Setup e Run do Back-End e da Infra(docker)
--- 
1) abrir o projeto no vscode
2) abrir docker desktop

extensões úteis:
- ThunderClient = conseguir fazer as requests e ver as responses da api
- Trx viewer = permite visualizar arquivos .trx
- Coverage Gutters = faz um display de cobertura gerado por xml
- Live Server(opcional)
- C# Dev Kit(opcional)

3) 
```bash
dotnet --version #checar se sdk do dotnet está instalado localmente na máquina
```
4) 
```bash
docker --version #verificar se docker cli está instalado localmente na máquina
```

5) 
```bash
docker build -t media-escolar . #constrói a imagem(dockerfile)
```
6) 
```bash
docker run -p 8080:8080 media-escolar #(roda um container em cima da imagem)
```
testar metoodos:
```bash
[POST] https//:LocalHost:8080/alunos #CadastrarAlunoReq
    body: 
    {
        "id": 1,
        "nome": "Enzo",
        "nota1": null,
        "nota2": null
    }
    #cadastra um aluno com ID e Nome(required)
```
```bash
[GET] https//:LocalHost:8080/alunos 
    Response:
    body: 
    [{
        "id": 1,
        "nome": "Enzo",
        "nota1": null,
        "nota2": null
    }]
    #retorna listagem de alunos
```
```bash
[POST] https//:LocalHost:8080/alunos/1/notas #RegistrarNotasReq
    body: 
    {
        "nota1": 5.5,
        "nota2": 8.0
    }
```
```bash
[GET] https//:LocalHost:8080/alunos/1 #pesquisa por ID 
    Response:
    body: 
    [{
        "id": 1,
        "nome": "Enzo",
        "nota1": null,
        "nota2": null
    }]
```



# Testes
--- 
```bash
#na root do projeto
dotnet test #executa todas as suites de teste (Unitários, regressão e API)
```
```bash
dotnet test --filter "FullyQualifiedName=namespace.testClass.methodName" 
#testes unitários locais específicos
```
```bash
dotnet test -logger "trx;LogFileName=RegistroEvidências" --collect "XPlat Code Coverage"
#realiza todos os testes, registra em arquivos de evidência .trx no diretório TestResults 
```
```bash
reportgenerator -reports:"TestResults/**/coverage.cobertura.xml" -targetdir:"coveragereport" -reporttypes:Html
```