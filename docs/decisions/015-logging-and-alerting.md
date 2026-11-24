# ADR-015: Use CloudWatch for logs and AWS alarms, PostHog for errors (and product analytics), and a paging tool for alerts

## Status

Proposed. **The final choice is deferred until we are close to launch.** Current lean is Option F (PostHog) over Option B (Sentry), mainly because the free tier covers launch volume.

## Date

2026-11-19 (updated 2026-11-23)

## Timing

We do not need to pick or pay for any of these tools now. Until we are close to launch:

- Rely on what ECS and AWS give for free. Container logs go to CloudWatch Logs and AWS metrics go to CloudWatch.
- Write structured JSON logs with secrets redacted from the start. This costs nothing and works with every option.
- Do not set up PostHog, Sentry, PagerDuty, Datadog, or any other paid account yet. A free PostHog project is fine for a staging spike if we want to validate the SDK before launch.

Revisit this ADR before the first production release, and before the load tests in [ADR-007](./007-load-testing-framework.md) if we want dashboards for them. Prices and free tiers change, so re-check them then. The recommendation below is where we would start today.

## Context

[ADR-003](./003-api-runtime-and-compute.md) says a person should be paged "only when something is actually wrong" and lists what pages. It leaves the tooling open: "observability tooling. Each has its own item." [ADR-007](./007-load-testing-framework.md) also waits on this ADR for dashboards. This ADR picks the tools for logs, error tracking, and paging. It is meant to be cheap at launch and easy to change.

What we need:

- **Logs** from the API, the worker, and the sports-data poller. Fastify writes JSON logs. ECS sends them to CloudWatch Logs by default.
- **Error tracking** for the API and the Expo app (crashes and unhandled errors), grouped by release.
- **Alerts that reach a person.** The paging list is: ALB 5xx rate, p95 latency, API task count at maximum, database CPU and connections, dead-letter queue depth, and sports-data staleness. [ADR-005](./005-payment-service.md) adds RevenueCat webhook lag, purchases missing from the ledger, and refund rate. [ADR-006](./006-app-notifications.md) adds push ticket and receipt errors.
- **An outside check** that the API answers, since a dead ALB cannot report on itself.
- **A small team.** One or two people get paged. Phone or SMS must work at night.
- **Money and personal data.** Logs must not hold tokens, card data, or more personal data than needed. The ledger in Postgres is the audit record, not the logs.

Prices below are US list prices (CloudWatch/Sentry/etc. checked 2026-11-19; PostHog checked 2026-11-23). Volumes are our estimates: launch is under 10 GB of logs and under 50,000 errors per month.

## Options Considered

### Option A: CloudWatch only

CloudWatch Logs, CloudWatch alarms, SNS for notifications, and AWS Chatbot to post in Slack.

- Pros: Already in the AWS account. ECS and ALB send logs and metrics with no extra setup. Free tier covers 5 GB of logs, 10 alarm metrics, and 3 dashboards. Logs cost $0.50 per GB ingested and $0.03 per GB per month stored. Alarms cost $0.10 per alarm metric.
- Cons: No on-call schedule, no escalation, and no phone call alerts without extra work. No error grouping, and nothing for the mobile app. Logs Insights is slower to use than a hosted log tool.

### Option B: CloudWatch + Sentry + PagerDuty Free

CloudWatch holds logs and raises alarms. Alarms go through SNS to PagerDuty. Sentry tracks errors in the API, worker, and Expo app.

- Pros: Each tool does one job. Sentry Team is $26 per month with unlimited users, 50,000 errors, 5 GB of logs, and 1 uptime monitor. PagerDuty Free allows 5 users and 100 SMS or phone notifications per month. Professional is $21 per user per month when we outgrow it.
- Cons: Three vendors and three logins. Sentry is the most likely bill to grow, at $0.0003625 per error between 50,000 and 100,000. A crash loop in the app can use the quota fast, so we need sampling and rate limits.

### Option C: Better Stack for everything

Better Stack handles logs, uptime, error tracking, on-call, and a status page.

- Pros: One vendor. Responders cost $29 per month each (yearly billing). Uptime (10 monitors), error tracking (100,000 exceptions), and on-call scheduling are included. Error tracking works with the Sentry SDK. Logs start at the Nano bundle, $38 per month for 40 GB in the US region, with 30 days of retention.
- Cons: We must ship logs from CloudWatch or change the ECS log driver. Its free tier says "personal projects", so we assume a paid plan. Smaller company than AWS or Sentry. We would still keep CloudWatch alarms for AWS metrics such as database CPU.

### Option D: Grafana Cloud

- Pros: The free tier has 50 GB of logs (14 days), 10,000 metric series, and 3 IRM (on-call) users. Pro is $19 per month plus usage, with 30-day log retention. Good dashboards.
- Cons: No error tracking for the backend or the Expo app. We must forward CloudWatch logs and metrics into it, which is real setup. Metrics are billed per active series ($6.50 per 1,000 above the free amount), which is harder to predict. We would run a second tool for errors anyway.

### Option E: Datadog

Datadog covers logs, AWS metrics, error tracking, on-call, and outside checks (Synthetics) in one product. Fanatics, a comparable betting company, uses it (see [ADR-007](./007-load-testing-framework.md)). Prices are annual list prices.

- Pros: One vendor and one login. Logs, metrics, traces, and errors link to each other, which makes incidents faster to work through. Error Tracking supports Node.js and React Native. On-Call is $20 per seat per month. Synthetic API tests are $5 per 10,000 runs. Logs can archive to our own S3 bucket.
- Cons: It is the most expensive option at launch, and the bill has many meters. Infrastructure Pro is $15 per host per month. Logs cost $0.10 per GB ingested plus $1.70 per million indexed events with 15-day retention. Error Tracking is $25 per month for the first 50,000 errors. Custom metrics are $5 per 100. APM (traces) is $31 per host on top. A log spike during a pack drop raises the bill directly. We would need to set indexing filters and budgets from the start. We did not confirm how Fargate tasks count as hosts.

Rough launch cost, assuming 3 Fargate tasks billed as hosts, 10 GB of logs at about 1 KB per line (10 million events), and 2 on-call seats: $45 infrastructure + $18 logs + $25 errors + $40 on-call = **about $130 per month**, without APM. That is about 4 times Option B.

### Option F: CloudWatch + PostHog + PagerDuty Free

CloudWatch holds container logs and raises AWS metric alarms. Alarms go through SNS to PagerDuty. PostHog Cloud tracks errors in the API, worker, Lambdas, and Expo app, and can also take product analytics, feature flags, session replay, and (optionally) application logs.

Free tier checked on 2026-11-23 (resets monthly, no card required on the free plan): 100,000 error exceptions, 1M analytics events, 10 GB logs ingested (14-day retention), 1M feature-flag requests, 5,000 session replays. Pay-as-you-go keeps the same free allowance; overage starts at about $0.00037 per exception and $0.25 per GB of logs. Billing limits stop capture at a spend cap.

- Pros: One SDK covers backend and Expo. Free tier is larger than Sentry Team's included errors (100k vs 50k) and costs $0 at launch if we stay under it. Product analytics and feature flags come with the same project, so we avoid a second product tool later. Error alerts go to Slack or a webhook; spike alerts exist for bad deploys. Unlimited team members on free.
- Cons: PostHog does not page a phone. Infra paging still needs CloudWatch + SNS + PagerDuty (same as Option B). Free plan is one project (staging and production share usage, or we pay for more projects). No built-in outside uptime check like Sentry's monitor — use a cheap third-party check or Cloudflare. Logs in PostHog are optional and default to 14 days; we still keep CloudWatch as the ECS default. Self-hosting PostHog on ECS is possible but out of scope; we use PostHog Cloud.

Rough launch cost if we stay inside free limits: CloudWatch only (~$4). Same PagerDuty Free path as Option B. That undercuts Option B's ~$30 mainly by dropping the Sentry Team seat.

Not evaluated: New Relic. It prices per GB and per user, and we have no reason to prefer it over Datadog.

## Decision

We choose **Option F**: CloudWatch for logs and AWS metrics, PostHog for errors (and product analytics when we need it), and PagerDuty for paging. Estimated cost at launch is about **$4 per month** in production if we stay inside PostHog's free tier:

| Item                                                         | Monthly |
| ------------------------------------------------------------ | ------- |
| CloudWatch Logs, 10 GB ingested, 5 GB free, 30-day retention | ~$3     |
| CloudWatch alarms, about 20 alarm metrics, 10 free           | ~$1     |
| PostHog (errors + analytics inside free tier)                | $0      |
| PagerDuty Free                                               | $0      |
| **Total**                                                    | **~$4** |

Option B (Sentry) remains the fallback if PostHog's React Native / Expo error tracking or source maps fall short before launch. Re-check then.

Why:

1. **Cheapest path that still reaches a phone.** Option A cannot page. PostHog's free tier covers launch error volume; Sentry Team is $26 per month for a smaller included quota. Datadog stays the premium incident product and is still about 4× Option B.
2. **No new work for logs and AWS metrics.** ECS, ALB, RDS, and the DLQ already report to CloudWatch. We write alarms in Terraform and add no agents. PostHog Logs are optional later if CloudWatch search becomes painful.
3. **One product tool for app and API.** `posthog-node` on the server and `posthog-react-native` in Expo. Same project for errors and product events. Feature flags and session replay are available without a new vendor.
4. **Easy to swap.** Error SDKs are isolated. If PostHog fails us, Sentry or Better Stack can replace it without touching CloudWatch alarms.

We accept that paging stays on AWS + PagerDuty, and that PostHog free is one project. We set billing limits on errors and analytics so a crash loop cannot start a bill by surprise.

## Consequences

- **Logs.** Log JSON with pino. Include request ID, user ID, and release. Redact `authorization`, cookies, tokens, and payment fields. Never log full request bodies on purchase routes. Keep CloudWatch as the primary log store from the ECS `awslogs` driver. Do not ship full container logs to PostHog at launch.
- **Retention.** Set CloudWatch retention in Terraform: 30 days in production, 7 days in staging. If SOC 2 or PCI work needs more, export to S3 (see [ADR-014](./014-domain-hosting-and-ddos-protection.md)). [ADR-004](./004-auth-service.md) streams Auth0 logs to the same account.
- **Alarms.** Write one CloudWatch alarm per item on the paging list above, in Terraform. Send these to PagerDuty through SNS. Send everything else (warnings, Cloudflare traffic spikes, PostHog issue-created alerts) to Slack with AWS Chatbot or PostHog's Slack integration.
- **Page rarely.** Each alarm needs a short runbook link. If an alarm fires and needs no action, delete it or move it to Slack.
- **PostHog on ECS Fargate (API and worker).** Use PostHog Cloud, not a self-hosted PostHog cluster. Create one long-lived `posthog-node` client per process (module scope), with `enableExceptionAutocapture: true`. Store the project API key and host (`https://us.i.posthog.com` or EU) in the task definition / Secrets Manager. Tag events with `environment` (`staging` / `production`), `service` (`api` / `worker` / `sports-poller`), and release/git sha. On container stop, call `await client.shutdown()` from the SIGTERM handler so the last batch flushes before the task exits. Upload Node source maps from CircleCI on deploy.
- **PostHog on Lambda (glue only).** [ADR-003](./003-api-runtime-and-compute.md) keeps the API on Fargate and uses Lambda only for short event-driven glue. For those functions: create the `PostHog` client outside the handler so warm containers reuse it; call `captureException` (or autocapture) inside the handler; before return, `flush()` and race it against `context.getRemainingTimeInMillis() - 100` so a cold flush cannot eat the whole timeout. Do not call `shutdown()` on every invocation — that tears down a client the next warm invoke would reuse.
- **PostHog in Expo.** Use `posthog-react-native` (Expo's `eas integrations:posthog:connect` is fine). Enable exception autocapture. Upload JS source maps (and native symbols if we need native crash stacks) from EAS builds. Identify the user after auth so errors join product analytics.
- **Outside check.** PostHog has no Sentry-style uptime monitor. Add a cheap external HTTP check on the public health endpoint through Cloudflare (or a free Better Stack / similar monitor) and page through the same PagerDuty path if it fails.
- **PagerDuty Free limits.** 100 SMS or phone notifications per month. Test that a real page arrives on both iOS and Android. Move to Professional ($21 per user) if we pass the limit or need schedules and escalation.
- **Dashboards.** Use the 3 free CloudWatch dashboards for load tests ([ADR-007](./007-load-testing-framework.md)) and drop days. Use PostHog insights for product and error trends. Revisit Grafana Cloud if we need more infra charts.
- **Revisit** when monthly cost passes about $100, when there are more than 2 on-call people, when searching logs in CloudWatch becomes the slowest part of an incident, or if Expo error symbolication in PostHog is weaker than Sentry before launch.

## Sources

- [Amazon CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [PostHog pricing](https://posthog.com/pricing), [Error Tracking pricing](https://posthog.com/docs/error-tracking/pricing), [Logs pricing](https://posthog.com/docs/logs/pricing)
- [PostHog Node.js library](https://posthog.com/docs/libraries/node), [Node error tracking](https://posthog.com/docs/error-tracking/installation/node)
- [Expo + PostHog](https://docs.expo.dev/guides/using-posthog/)
- [Sentry pricing](https://sentry.io/pricing/)
- [PagerDuty pricing](https://www.pagerduty.com/pricing/incident-management/)
- [Better Stack pricing](https://betterstack.com/pricing)
- [Grafana Cloud pricing](https://grafana.com/pricing/)
- [Datadog pricing](https://www.datadoghq.com/pricing/) and [Datadog price list](https://www.datadoghq.com/pricing/list/)
- [ADR-003: Use Node.js with TypeScript on ECS Fargate for the API](./003-api-runtime-and-compute.md)
- [ADR-004: Auth service](./004-auth-service.md)
- [ADR-005: Payment service](./005-payment-service.md)
- [ADR-006: App notifications](./006-app-notifications.md)
- [ADR-007: Load testing framework](./007-load-testing-framework.md)
- [ADR-014: Use Cloudflare for domain hosting and DDoS protection](./014-domain-hosting-and-ddos-protection.md)
