# Split tests across CI runners

This example is a template to adapt, not a workflow TestBox dispatches. Install the TestBox/CLI versions containing this feature first. Keep the application's existing dependency, database and server setup in each test job. The selected runner must include TestBox's standard HTMLRunner or StreamingRunner.

```yaml
jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      # Checkout the same commit and run your existing CommandBox/application setup here.
      - name: Run this shard
        run: >-
          box testbox run runner=serial
          shard=${{ matrix.shard }}/4
          shardRunId=${{ github.run_id }}-${{ github.run_attempt }}-${{ github.sha }}
          outputFile=results/shard-${{ matrix.shard }}.json
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: testbox-shard-${{ matrix.shard }}
          path: results/shard-${{ matrix.shard }}.json
          if-no-files-found: error

  combine:
    needs: tests
    if: always()
    runs-on: ubuntu-latest
    steps:
      # Checkout the same commit and install CommandBox, this CLI and TestBox here.
      - uses: actions/download-artifact@v4
        with:
          pattern: testbox-shard-*
          path: downloaded-results
      - name: Verify and combine every shard
        run: box testbox merge directory=downloaded-results outputFile=results/combined.json
```

The comments stand for application-specific setup that must be filled in. The aggregation job needs TestBox but does not need an application server or database. It recursively reads JSON files, so artifact subdirectories are fine. Use a dedicated report directory; unrelated JSON and duplicate retry artifacts deliberately fail verification. Use unique names/patterns for separate engine or configuration matrices. Do not combine reruns with the original attempt.

A CI cancellation can prevent the combination job from running. Use your platform's cancellation and job timeouts; a provider's local Ctrl-C contract does not control an independently scheduled CI matrix. No hosted performance run has been measured for this implementation.

For other CI systems, use the same one-based index/count, shared run identity and artifact merge. TestBox does not require GitHub APIs or credentials.
