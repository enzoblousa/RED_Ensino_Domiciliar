# Screenshot Automático da Execução na Pipeline — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the manually-committed pipeline screenshot (`evidencias/EvidenciaFalha1.png`) with an automated screenshot, captured by the CI pipeline itself, of the real API JSON response after exercising the cadastro → notas → consulta flow against the built Docker image.

**Architecture:** A new step in `.github/workflows/ci.yml`, placed after "Executar testes com cobertura" and before "Publicar evidencias", boots the already-built `media-escolar` Docker image, drives the business flow via `curl`, and uses Playwright's headless Chromium (invoked via `npx`, no new project/dependency needed) to screenshot the final `GET /alunos/{id}` JSON response into `./TestResults/screenshot-execucao.png`. That file is picked up automatically by the existing `evidencias-pipeline` artifact upload (its `path` is already `./TestResults`). A second new step tears the container down unconditionally.

**Tech Stack:** GitHub Actions (`ubuntu-latest`), Docker, `curl`, `jq` (preinstalled on `ubuntu-latest`), Playwright CLI via `npx` (Chromium headless).

Reference spec: `docs/superpowers/specs/2026-06-22-screenshot-automatico-pipeline-design.md`

---

### Task 1: Remove the manual screenshot evidence

**Files:**
- Delete: `evidencias/EvidenciaFalha1.png`
- Modify: `README.md:60` (the "Screenshot da execução da pipeline" bullet under `## Evidências`)

- [ ] **Step 1: Delete the manually-committed screenshot**

```bash
git rm evidencias/EvidenciaFalha1.png
```

Expected: `rm 'evidencias/EvidenciaFalha1.png'` printed, file removed from the working tree.

- [ ] **Step 2: Remove the now-stale bullet from the README**

In `README.md`, find this line under `## Evidências`:

```markdown
- Screenshot da execução da pipeline: `evidencias/EvidenciaFalha1.png` (print da run do GitHub Actions)
```

Delete the entire line. Leave the surrounding bullets (`Execução da pipeline...`, `Log de testes...`, `Relatório do linter...`) untouched — they'll be re-ordered/extended in Task 3.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Remove manual pipeline screenshot evidence"
```

---

### Task 2: Add the automated screenshot step to the CI workflow

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Insert the capture step and the teardown step**

Open `.github/workflows/ci.yml`. Find this block:

```yaml
      - name: Executar testes com cobertura
        run: dotnet test MediaEscolar.sln --logger "trx;LogFileName=test-results.trx" --collect:"XPlat Code Coverage" --results-directory ./TestResults

      - name: Publicar evidencias (relatorio do linter, resultados de teste e cobertura)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: evidencias-pipeline
          path: ./TestResults
```

Replace it with:

```yaml
      - name: Executar testes com cobertura
        run: dotnet test MediaEscolar.sln --logger "trx;LogFileName=test-results.trx" --collect:"XPlat Code Coverage" --results-directory ./TestResults

      - name: Capturar screenshot da execução
        run: |
          docker run -d --name media-escolar -p 8080:8080 media-escolar

          echo "Aguardando a API responder..."
          for i in $(seq 1 30); do
            if curl -sf http://localhost:8080/alunos > /dev/null; then
              echo "API respondendo."
              break
            fi
            if [ "$i" -eq 30 ]; then
              echo "API nao respondeu a tempo."
              docker logs media-escolar
              exit 1
            fi
            sleep 1
          done

          ALUNO_ID=$(curl -sf -X POST http://localhost:8080/alunos \
            -H "Content-Type: application/json" \
            -d '{"nome":"Maria"}' | jq -r '.id')

          curl -sf -X POST "http://localhost:8080/alunos/${ALUNO_ID}/notas" \
            -H "Content-Type: application/json" \
            -d '{"nota1":8.0,"nota2":6.0}' > /dev/null

          npx --yes playwright@1.48.0 install --with-deps chromium
          npx --yes playwright@1.48.0 screenshot "http://localhost:8080/alunos/${ALUNO_ID}" ./TestResults/screenshot-execucao.png

      - name: Encerrar container da aplicacao
        if: always()
        run: docker rm -f media-escolar || true

      - name: Publicar evidencias (relatorio do linter, resultados de teste, cobertura e screenshot)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: evidencias-pipeline
          path: ./TestResults
```

Note the renamed last step (`relatorio do linter, resultados de teste, cobertura e screenshot`) — it now documents that the screenshot is included too.

- [ ] **Step 2: Validate the YAML is syntactically correct**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "YAML válido"
```

Expected: `YAML válido` printed, no traceback.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "Add automated execution screenshot step to CI pipeline"
```

---

### Task 3: Update README documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the "Pipeline CI/CD" step list**

Find this block:

```markdown
## Pipeline CI/CD
A esteira (`.github/workflows/ci.yml`) executa, a cada push/PR para `main`:
1. Checkout do código (`actions/checkout@v4`)
2. Setup do .NET (`actions/setup-dotnet@v4`)
3. Build da imagem Docker (`docker build`)
4. Análise estática (`dotnet format --verify-no-changes --report ./TestResults`, gerando `format-report.json`)
5. Execução dos testes com cobertura (`dotnet test --collect:"XPlat Code Coverage"`)
6. Publicação de evidências (relatório do linter `format-report.json`, relatório de testes `.trx` e cobertura `coverage.cobertura.xml` como artifacts)
```

Replace it with:

```markdown
## Pipeline CI/CD
A esteira (`.github/workflows/ci.yml`) executa, a cada push/PR para `main`:
1. Checkout do código (`actions/checkout@v4`)
2. Setup do .NET (`actions/setup-dotnet@v4`)
3. Build da imagem Docker (`docker build`)
4. Análise estática (`dotnet format --verify-no-changes --report ./TestResults`, gerando `format-report.json`)
5. Execução dos testes com cobertura (`dotnet test --collect:"XPlat Code Coverage"`)
6. Captura automática de screenshot: sobe o container da imagem buildada, executa o fluxo cadastro → notas → consulta via `curl` e usa o Playwright (Chromium headless) para fotografar o JSON final em `screenshot-execucao.png`
7. Publicação de evidências (relatório do linter, relatório de testes, cobertura e screenshot como artifacts)
```

- [ ] **Step 2: Update the "Evidências" section**

Find this block:

```markdown
## Evidências
- Execução da pipeline no GitHub Actions: https://github.com/enzoblousa/RED_Ensino_Domiciliar/actions/runs/27924637273
- Log de testes passando localmente: ver `evidencias/correcao-teste.txt`
- Relatório do linter: `format-report.json`, gerado pelo `dotnet format --report` e publicado como artifact `evidencias-pipeline` em cada execução
```

(this is the same block from Task 1 after the manual-screenshot bullet was removed)

Replace it with:

```markdown
## Evidências
- Execução da pipeline no GitHub Actions: https://github.com/enzoblousa/RED_Ensino_Domiciliar/actions/runs/27924637273
- Log de testes passando localmente: ver `evidencias/correcao-teste.txt`
- Relatório do linter: `format-report.json`, gerado pelo `dotnet format --report` e publicado como artifact `evidencias-pipeline` em cada execução
- Screenshot da execução: `screenshot-execucao.png`, gerado automaticamente em cada execução (sem intervenção manual) e publicado no artifact `evidencias-pipeline` — baixável na página da run correspondente em GitHub Actions
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document automated screenshot step in README"
```

---

### Task 4: Push and confirm the pipeline run

- [ ] **Step 1: Push all commits from this plan**

```bash
git push origin main
```

Expected: push succeeds, three new commits land on `origin/main` (one per task above).

- [ ] **Step 2: Watch the triggered pipeline run**

```bash
gh run watch --exit-status
```

(if `gh run watch` isn't available or doesn't pick up the right run automatically, use `gh run list --branch main --limit 1` to get the run ID, then `gh run watch <run-id> --exit-status`)

Expected: all jobs succeed, including the new "Capturar screenshot da execução" and "Encerrar container da aplicacao" steps.

- [ ] **Step 3: Confirm the screenshot artifact was produced**

```bash
gh run download --name evidencias-pipeline -D /tmp/evidencias-check
ls -la /tmp/evidencias-check/screenshot-execucao.png
```

Expected: `screenshot-execucao.png` exists with non-zero size. Optionally open it to confirm it shows the expected JSON (`"situacao":"Aprovado"` for the `nota1=8.0, nota2=6.0` flow used in the step).

---

## Notes for whoever executes this plan

- The exact `npx playwright screenshot <url> <path>` command and the `--install --with-deps chromium` step were verified locally against a throwaway static JSON server before this plan was written — the syntax is confirmed correct, not guessed.
- The `docker run -p 8080:8080 media-escolar` invocation and the assumption that the API is reachable at `http://localhost:8080` were **not** re-verified in this environment (no Docker daemon was running here) — they're taken directly from the README's existing "Como executar com Docker" instructions, which already document this exact command working. If Task 2's CI run fails at the "Aguardando a API responder" loop, check `docker logs media-escolar` (the step already prints it on timeout) before assuming the screenshot logic is wrong.
- `jq` is assumed preinstalled on `ubuntu-latest` GitHub-hosted runners (it is, as of all current runner images). No install step was added for it.
