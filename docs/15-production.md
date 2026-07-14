# Security と production boundary

## message source を code とみなさない

MF2 function と markup の identifier は application registry の key です。任意の reflection、module load、HTML evaluation に接続してはいけません。registry は explicit allowlist にします。

## custom handler

handler は read-only の最小 context を受け、execution time と resource usage を制限します。ネットワーク、filesystem、mutable global state に触れる handler は結果の再現性と call-by-need semantics を壊しやすくなります。

## Unicode

- identifier/literal の invisible character と bidi control を UI で可視化する。
- translation editor では confusable と mixed-script を警告する。
- pattern selection key は仕様上 NFC normalization が必要。
- untrusted outer format の decoding error を parser 前に処理する。

reference runtime は NFC library を同梱していないため、非 ASCII key の canonical equivalence は production integration で補う必要があります。

## rich text

`MarkupOutput` を HTML string に連結しません。identifier ごとに許可した component/function へ mapping し、option value も component 側で validate します。

## locale backend

全 locale の正しい number/date/unit/currency output には current CLDR data、TZDB、calendar implementation が必要です。reference backend の locale-neutral output を production UI の完成形として使わず、ICU 等の handler を注入します。

## resource limits

parser fuel は nontermination を防ぎますが、極端に長い message、巨大な number literal、variant 数には application-level size limit も設定してください。`Integer` は arbitrary precision なので memory exhaustion の対象になります。

## checklist

- source size、variant count、literal length の上限
- registry allowlist と handler timeout
- CLDR/TZDB version pin
- NFC normalization
- markup component allowlist
- diagnostic の logging と user-safe fallback
- translated message を fixture と locale matrix で test

## 仕様

- [MF2 Security Considerations](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#security-considerations)
- [Unicode Security Mechanisms, UTS #39](https://www.unicode.org/reports/tr39/)
- [Unicode Normalization Forms, UAX #15](https://www.unicode.org/reports/tr15/)
- [Unicode Bidirectional Algorithm, UAX #9](https://www.unicode.org/reports/tr9/)

