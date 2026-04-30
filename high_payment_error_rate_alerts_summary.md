# High Payment Error Rate Alerts Summary

1. **WarningPaymentErrorRateAlert**
   - **Severity:** Warning
   - **Condition:** Payment error rate exceeds 0.001 for 20 minutes.
   - **Description:** This alert indicates an elevated payment error rate. Investigation is recommended to identify potential issues before escalation.
   - **Escalation:** If not resolved in 20 minutes, escalate to the payment processing manager.
   - **Runbook:** [Payment Errors Runbook](https://internal-runbook.yara.com/payment-errors)
   - **Recovery:** Alert resolves when payment error rate returns below 0.001.

2. **CriticalPaymentIssuesAlert**
   - **Severity:** Critical
   - **Condition:** Payment error rate exceeds 0.001 or duplicate payments exceed 3 within 5 minutes.
   - **Description:** Critical payment issues detected. Immediate investigation and action are required.
   - **Escalation:** If not resolved in 10 minutes, escalate to the payment processing manager.
   - **Runbook:** [Critical Payment Errors Runbook](https://internal-runbook.yara.com/payment-errors-critical)
   - **Recovery:** Alert resolves when payment error rate and duplicate payments return to normal thresholds.

3. **DynamicPaymentErrorRateAlert**
   - **Severity:** Warning
   - **Condition:** Payment error rate exceeds 65% above the 2-day average baseline for more than 8 minutes, with minimum traffic threshold.
   - **Description:** This alert detects significant deviations in payment error rate while reducing false positives by using a dynamic threshold.
   - **Escalation:** If persistent for 8 minutes, escalate to the payment processing manager.
   - **Runbook:** [Dynamic Payment Errors Runbook](https://internal-runbook.yara.com/payment-errors-dynamic)
   - **Recovery:** Alert resolves when payment error rate returns below the dynamic threshold.

4. **WarningPaymentErrorRateAlert (with Dependency)**
   - **Severity:** Warning
   - **Condition:** Payment error rate exceeds 0.001 for 20 minutes, but suppressed if CriticalPaymentIssuesAlert is firing.
   - **Description:** This alert provides early warning but is suppressed to reduce noise if a critical alert is active.
   - **Escalation:** If not resolved in 20 minutes, escalate to the payment processing manager.
   - **Runbook:** [Payment Errors Runbook](https://internal-runbook.yara.com/payment-errors)
   - **Recovery:** Alert resolves when payment error rate returns below 0.001.
