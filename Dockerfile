#Dockerfile multi-stage, um roda o sdk inteiro o outro apenas o runtime do dotnet ASP

#faça um pull da imagem do dotnet sdk(compilador, nugetpackages, dotnet publish etc) e nomeia de build para reuso
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
#define o diretório /src como diretório de trabalho, "entra nele"
WORKDIR /src
#copia todos os arquivos do projeto e cola dentro do /src do contâiner = o priemeiro ponto é local(host machine) o seugndo é o destination path(contâiner machine)
COPY . .
#compila e publica apenas o projeto proj da api(não a solução inteira ou testes) em modo release e guardando o resultado em /app
RUN dotnet publish src/MediaEscolar.Api/MediaEscolar.Api.csproj -c Release -o /app


#imagem final, runtime(apenas o necessário para rodar uma aplicação ASP.NET Core já compilada) ou seja MAIS AGILIDADE E MENOS CUSTO DE MEMORIA E ARMAZENAMENTO
#faz um pull do runtime ASP.NET Runtime 
FROM mcr.microsoft.com/dotnet/aspnet:8.0
#define o /app como o workfolder no container 
WORKDIR /app
#como se fosse a ponte, copya o resultado da build passada guardada em /app e guarda na /app deste estágio final
COPY --from=build /app .
#variável de ambiente, escuta todas as portas da api:8080 dentro do container
ENV ASPNETCORE_URLS=http://+:8080
#declara que a porta do contâiner é 8080
EXPOSE 8080
#comando executado assim que o contâiner é iniciado. 
ENTRYPOINT ["dotnet", "MediaEscolar.Api.dll"]



# Por que multi-stage?
# Sem o multi-stage, a imagem final teria o SDK inteiro (compilador, ferramentas de build) ocupando espaço e superfície de ataque sem necessidade em produção 
# Só o estágio de build precisa disso. Com dois estágios, a imagem publicada (aspnet:8.0 + DLLs) fica bem menor e mais segura, e o código-fonte/projetos de teste nem chegam a existir na imagem final.