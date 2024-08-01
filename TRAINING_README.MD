# Welcome to the OPA Rego Training Ground for SCuBA <!-- omit in toc -->

## Rules

1) DO NOT push any changes
2) DO NOT merge this branch into main
3) DO NOT look at the code in the other branches to solve the challenges
4) DO ask questions
5) Look at the Training Ground README!

## Table of Contents

- [Breakdown of SCuBA file structure](docs/training/structure.md)
- [Rego Resources](docs/training/resources.md)
- [Rego Cheat Sheet](docs/training/cheatsheet.md)
- [Rego Policy Creation](docs/training//rego_rules.md)
- [Rego Unit Tests](docs/training/unit_test.md)
- [README for Training Ground](docs/training/training_ground.md)

## Overview

Welcome to the SCuBA training ground for OPA Rego. This branch is designed to be used in tandum with the training videos. The training videos discuss basic syntax and capabilities of OPA Rego. This branch is intended to aid in becoming more familiar with Rego and how it is utilized for SCuBA. Each Product (i.e., Sharepoint, Power Platform, Teams, Exchange Online, Defender, and Azure Active Directory) has an overall level assigned to it from 1 (easy) to 3 (hard). Each section in a product will have an indication of difficulty relative to the other sections in the product and some may have recommendations to complete other things first before attempting. I highly recommend reading the comments present as they are not developer comments. They exist to help you understand how Rego capabilities can be utilized in certain situations as well as why one is used over the other. As this branch is intended as a learning aid, there will be techniques taught that are no longer used in SCuBA. I will notate in the comments in these cases; However, I recommend still learning because they are part of Rego.

### Important Notation Key

You will notice that almost the entire code base has been changed for practice. Just as it took us a long time to write the code base, it will take you
a long time to finish all the challenges. So for the challengers that have limited time, you can ctrl+f for the target notation below. The target notation indicates challenges that cover important techniques that need to be practiced before moving on to the next level.

```Rego
#** Target **#
```

### Where to Start

Keep in mind the Table of Contents has links to resources you will need in this training ground. To get started, look at [SharepointConfig.rego](PowerShell\ScubaGear\Rego\SharepointConfig.rego)
