---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test report generation
---

The following three pipelines are created while generating the allure-report:

- `omnibus-gitlab` pipeline
- TRIGGERED_CE/EE_PIPELINE child pipeline (Manually Triggered)
- QA-SUBSET-TEST child pipeline

## `omnibus-gitlab` MR Pipeline

An `omnibus-gitlab` project MR pipeline can be triggered in two ways:

- manually running the pipeline
- a MR exists and a commit is pushed to the repository

The tests in the pipeline are currently triggered manually by:

- `Trigger:ce-package` job
- `Trigger:ee-package` job

### Trigger:ce/ee-package job

These jobs can be triggered manually after the `generate-facts` job is completed. On triggering these jobs, a child pipeline is created.

The child pipeline, called `TRIGGERED_CE/EE_PIPELINE` is generated in the `omnibus-gitlab` repository.

## TRIGGERED_CE/EE_PIPELINE child pipeline

This child pipeline consists of a job called `qa-subset-test` which uses the `test-on-omnibus/main.gitlab-ci.yml` file of the main GitLab project.

### qa-subset-test job

The `qa-subset-test` job triggers another child pipeline in the `omnibus-gitlab` repository.
To get an allure report snapshot as a comment in the MR, following environment variables need to be passed to `qa-subset-test`.

| Environment Variable       | Description |
|----------------------------|-------------|
| `GITLAB_AUTH_TOKEN`        | This is used to give access to the Danger bot to post comment in `omnibus-gitlab` repository. We are using  `$DANGER_GITLAB_API_TOKEN` which is also being used for other Danger bot related access in `omnibugs-gitlab` as mentioned [ci-variable](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/development/ci-variables.md) |
| `ALLURE_MERGE_REQUEST_IID` | This denotes the MR ID which will be used by [e2e-test-report-job](#e2e-test-report-job) which inturn used `allure-report-publisher` to post message to MR with provided ID e.g. !6190 |

### qa-remaining-test-manual

The `qa-remaining-test-manual` job is a manual trigger pipeline. It triggers the same pipeline as `qa-subset-test` but runs the tests which aren't run as a part of `qa-subset-test` job.

The environment variables used in `qa-subset-test` are the same that are used in this job to generate the allure report.

## QA-SUBSET-TEST child pipeline

This pipeline runs a subset of all the orchestrated tests using GitLab QA project which in turn uses allure gem to generate report source files for each test that is executed and stores the files in a common folder. Certain orchestrated jobs like `instance`, `decomposition-single-db`, `decomposition-multiple-db` and `praefect` run only smoke tests which initially used to run the entire suite.

### e2e-test-report job

The `e2e-test-report` job includes [.generate-allure-report-base](https://gitlab.com/gitlab-org/quality/pipeline-common/-/blob/master/ci/allure-report.yml) job which uses the `allure-report-publisher` gem to collate all the report in the mentioned folder into a single report and uploads it to the s3 bucket.

It also posts the allure report as a comment on the MR having the ID passed in `ALLURE_MERGE_REQUEST_IID` variable in the [qa-subset-test](#qa-subset-test-job).

[allure-report-publisher](https://github.com/andrcuns/allure-report-publisher) is a gem which uses allure in the backend. It has been catered for GitLab to upload the report and post the comment to MR.

The entire flow of QA in `omnibus-gitlab` MR pipeline is as follows

```mermaid
flowchart TD
  B0 --->|MR pipeline triggered on each commit| A0
  A0 ---->|Creates child pipeline| A1
  A1 ---->|Creates child pipelines| A2
  A2 -->|"Once tests are successful calls e2e-test-report job"| B1
  A3 -.-|includes| A1
  B2 -.-|includes| B1
  B1 -->|Runs| C1
  C1 -.->|uploads report| C2
  C1 -.->|Posts report link as a comment on MR| B0
  C3 -.->|pulls| B2

  subgraph "Omnibus parent pipeline"
    direction LR
    B0(["Merge request"])
    A0["<strong>trigger-package</strong> stage
        Manual <strong>Trigger:ce/ee-package</strong>
        job kicked off"]
  end

  subgraph Trigger: CE/EE-job child pipeline
    direction TB
    A1["<strong>trigger-qa</strong> stage
        <strong>qa-subset-test</strong> job"]
    A3(["<code>test-on-omnibus/main.gitlab-ci.yml</code>
         from <code>gitlab-org/gitlab</code>"])
  end

  subgraph qa-subset-test
    direction TB
    A2["from
        <code>test-on-omnibus/main.gitlab-ci.yml</code>
        in
        <code>gitlab-org/gitlab</code>"]
    B1["<strong>report</strong> stage
        <strong>e2e-test-report<strong> job"]
    B2(["<strong>.generate-allure-report-base</strong> job
         from <code>quality/pipeline-common</code>"])
    C1["<code>allure-report-publisher</code> gem"]
    C2[("AWS S3
         <code>gitlab-qa-allure-report</code>
         in
         <code>eng-quality-ops-ci-cd-shared-infra</code>
         project")]
    C3["pulls
        <code>image _andrcuns/allure-report-publisher:1.6.0</code>"]
  end
```

## Demo for Allure report & QA pipelines

An in-depth video walkthrough of the pipeline and how to use Allure report
is available [on YouTube](https://youtu.be/_0dM6KLdCpw).
