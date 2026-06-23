# Dockerfile — explicação linha a linha

O `Dockerfile` da raiz builda a API (`MediaEscolar.Api`) numa imagem Docker usando **multi-stage build**: um estágio só para compilar (com o SDK completo do .NET, mais pesado) e outro só para rodar (com o runtime, bem mais leve). A imagem final não carrega nada do SDK/ferramentas de build — só o necessário para executar.

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/MediaEscolar.Api/MediaEscolar.Api.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "MediaEscolar.Api.dll"]
```

## Estágio 1 — `build`

- **`FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build`** — parte da imagem oficial do **SDK** do .NET 8 (inclui compilador, NuGet, `dotnet publish`, etc.). É a imagem mais pesada (centenas de MB), só existe para compilar — não vai para o container final. `AS build` dá um nome a esse estágio, para referenciar depois.
- **`WORKDIR /src`** — define `/src` como diretório de trabalho dentro do container; todos os comandos seguintes rodam a partir dali.
- **`COPY . .`** — copia todo o conteúdo do repositório (contexto do build, geralmente a raiz do projeto) para `/src` dentro do container. Isso inclui a solução, os projetos `src/` e `tests/`, etc.
- **`RUN dotnet publish src/MediaEscolar.Api/MediaEscolar.Api.csproj -c Release -o /app`** — compila e publica especificamente o projeto da API (não a solução inteira, não os testes) em modo `Release` (otimizado, sem símbolos de debug), gravando o resultado (DLLs, `.deps.json`, `appsettings.json`, etc.) em `/app`.

## Estágio 2 — imagem final (runtime)

- **`FROM mcr.microsoft.com/dotnet/aspnet:8.0`** — começa um estágio novo, do zero, a partir da imagem **ASP.NET Runtime** (não o SDK) — tem só o necessário para executar uma aplicação ASP.NET Core já compilada, é bem menor que a imagem de build. Como não tem `AS nome`, esse é o estágio "final": é o que efetivamente vira a imagem publicada.
- **`WORKDIR /app`** — define `/app` como diretório de trabalho neste novo estágio (container limpo, não tem relação com o `/app` do estágio anterior além do nome).
- **`COPY --from=build /app .`** — copia o conteúdo de `/app` **do estágio `build`** (onde o `dotnet publish` gravou os arquivos) para o `/app` deste estágio atual. É a ponte entre os dois estágios: só o resultado já compilado atravessa, nunca o código-fonte nem o SDK.
- **`ENV ASPNETCORE_URLS=http://+:8080`** — variável de ambiente que o ASP.NET Core lê para saber em qual endereço/porta escutar dentro do container. `+` significa "qualquer host", então a API escuta em todas as interfaces na porta `8080`.
- **`EXPOSE 8080`** — só documenta/declara que o container usa a porta `8080` (não publica a porta no host automaticamente — isso é feito no `docker run -p` ou no `docker-compose`, como aparece no step de screenshot do `.github/workflows/ci.yml`, que usa `-p 8080:8080`).
- **`ENTRYPOINT ["dotnet", "MediaEscolar.Api.dll"]`** — comando executado quando o container inicia: roda a DLL publicada com o runtime `dotnet`. É isso que efetivamente liga a API.

## Por que multi-stage?

Sem o multi-stage, a imagem final teria o SDK inteiro (compilador, ferramentas de build) ocupando espaço e superfície de ataque sem necessidade em produção — só o estágio de **build** precisa disso. Com dois estágios, a imagem publicada (`aspnet:8.0` + DLLs) fica bem menor e mais segura, e o código-fonte/projetos de teste nem chegam a existir na imagem final.
