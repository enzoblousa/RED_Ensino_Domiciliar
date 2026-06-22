# Design: API de Média Escolar — CI/CD com Docker

## Contexto

Atividade domiciliar da disciplina "Testes e Qualidade de Software" (ver `DocumentoProfessor/red-enzo.pdf`). Exige: aplicação simples empacotada em Docker, pipeline CI/CD com checkout, build, lint, testes automatizados e geração de evidências, além de uma simulação documentada de falha e correção.

Decisão geral: priorizar a stack mais simples possível dentro do que o aluno já conhece (.NET), evitando banco de dados e Docker Compose, já que nenhum dos dois é estritamente necessário para o escopo escolhido.

## Aplicação

API de Média Escolar (exemplo sugerido no próprio PDF), com armazenamento em memória (sem banco de dados).

Funcionalidades:
- Cadastrar aluno (nome).
- Registrar duas notas (validadas entre 0 e 10).
- Calcular a média e a situação (Aprovado se média ≥ 6, senão Reprovado).
- Listar alunos cadastrados.

## Stack

- **Linguagem/Framework**: .NET 8, ASP.NET Core Minimal API.
- **Testes**: xUnit + `coverlet.collector` (cobertura) + `Microsoft.AspNetCore.Mvc.Testing` (`WebApplicationFactory` para teste de integração).
- **Lint/análise estática**: `dotnet format --verify-no-changes` (formatter/analisadores embutidos do SDK, sem pacote adicional).
- **Containerização**: Dockerfile multi-stage (`sdk:8.0` para build, `aspnet:8.0` para runtime). Sem docker-compose — não há banco de dados nem múltiplos serviços.
- **CI/CD**: GitHub Actions (`.github/workflows/ci.yml`), já que o repositório remoto é GitHub (`enzoblousa/RED_Ensino_Domiciliar`).

## Estrutura de pastas

```
RED_Ensino_Domiciliar/
├── src/
│   └── MediaEscolar.Api/
│       ├── Program.cs
│       ├── Models/
│       │   └── Aluno.cs
│       └── MediaEscolar.Api.csproj
├── tests/
│   └── MediaEscolar.Tests/
│       ├── MediaCalculoTests.cs
│       ├── ApiIntegrationTests.cs
│       └── MediaEscolar.Tests.csproj
├── Dockerfile
├── .github/workflows/ci.yml
└── README.md
```

## Endpoints

- `POST /alunos` — cadastra aluno (nome) → retorna Id.
- `POST /alunos/{id}/notas` — registra nota1 e nota2 (valida 0–10, retorna 400 se inválido).
- `GET /alunos/{id}` — retorna aluno com média calculada e situação.
- `GET /alunos` — lista todos os alunos cadastrados.

Regra de negócio isolada em funções puras (`CalcularMedia`, `CalcularSituacao`) para serem testáveis sem precisar de uma requisição HTTP.

## Testes

| Tipo | Arquivo | Casos |
|---|---|---|
| Unidade (mín. 3) | `MediaCalculoTests.cs` | cálculo correto da média; aprovação (média ≥ 6); reprovação (média < 6); nota inválida (fora de 0–10) lança erro |
| Integração/API | `ApiIntegrationTests.cs` (via `WebApplicationFactory`) | fluxo completo: cadastra aluno → registra notas → `GET /alunos/{id}` retorna média/situação corretos via HTTP real |
| Regressão | em `MediaCalculoTests.cs` | trava o valor exato da nota de corte (6.0) na regra de aprovação |

Comando: `dotnet test --logger trx --collect:"XPlat Code Coverage"` → gera `.trx` (relatório de testes) e `coverage.cobertura.xml` (cobertura).

## Docker

Dockerfile multi-stage:
1. Stage `build` (`mcr.microsoft.com/dotnet/sdk:8.0`): restore + publish.
2. Stage final (`mcr.microsoft.com/dotnet/aspnet:8.0`): copia artefatos publicados, expõe porta 8080.

Execução:
```
docker build -t media-escolar .
docker run -p 8080:8080 media-escolar
```

## Pipeline CI/CD (`.github/workflows/ci.yml`)

Disparada em push/PR para `main`. Etapas:

1. **Checkout** — `actions/checkout@v4`.
2. **Setup .NET** — `actions/setup-dotnet@v4` (necessário para rodar build/test/lint diretamente no runner).
3. **Build da imagem Docker** — `docker build -t media-escolar .`.
4. **Análise estática/lint** — `dotnet format --verify-no-changes`.
5. **Testes automatizados** — `dotnet test --logger trx --collect:"XPlat Code Coverage"`.
6. **Geração de evidências** — `actions/upload-artifact@v4` publicando `.trx` e `coverage.cobertura.xml`; badge de status no README via URL padrão do GitHub Actions.

## Simulação de falha e correção (documentada no README)

1. Alterar temporariamente a regra de aprovação (ex.: `>= 6` → `> 6` em `CalcularSituacao`), quebrando o teste de regressão.
2. Rodar `dotnet test` (local ou pipeline) e capturar o log/print da falha.
3. Registrar a falha no README (print + trecho do log).
4. Corrigir (reverter para `>= 6`).
5. Rodar novamente e capturar o log/print com sucesso.
6. Registrar a correção no README.

## README

Segue o modelo de seções do PDF: Descrição, Tecnologias, Funcionalidades, Como executar com Docker, Como executar os testes, Pipeline CI/CD, Tipos de testes, Evidências, Falha simulada e correção, Conclusão — todo preenchido com conteúdo real do projeto, sem placeholders.

## Fora de escopo

- Banco de dados (persistência é em memória).
- Docker Compose (não há múltiplos serviços).
- Autenticação/autorização.
- Interface gráfica (somente API).
