# 한글 글꼴(나눔고딕)의 출처

**앱 번들에 들어간다**(2026-09-16부터, pubspec `fonts:` → 테마 `AppTheme.hangulFallback`). 골든 스냅샷도 같은 파일을 쓴다.
2026-09-14~16에는 `test/fonts/`에 테스트 전용으로 있었다.

| 파일 | 출처 | 커밋 | sha256 |
| --- | --- | --- | --- |
| `NanumGothic-Regular.ttf` | `github.com/google/fonts` `ofl/nanumgothic/` | `133ccbee9a8b408eb71f31a36ccb9116f5c695ad` | `76f45ef4a6bcff344c837c95a7dcc26e017e38b5846d5ae0cdcb5b86be2e2d31` |
| `NanumGothic-Bold.ttf` | 같음 | 같음 | `f96298f9fb18e364d2370f4c3ce948ac67a2b61af992d7234bc15c42b033c674` |
| `NanumGothic-OFL.txt` | 같은 폴더의 `OFL.txt` | 같음 | `eeacf16032901d0ed0456876ec77b8f0fda6b3fecec7d972f8543eb602e6c30f` |

- 라이선스: SIL Open Font License 1.1 — `NanumGothic-OFL.txt`로 확인했다. **글꼴 파일 자체의 name 테이블에는
  라이선스 문구가 없다**(저작권자 NHN Corporation만 있다). Reserved Font Name이 있으므로 파일을 수정·재명명해 배포하지 않는다.
- 받은 날: 2026-09-14. 받은 방법: `gh api -H "Accept: application/vnd.github.raw" repos/google/fonts/contents/ofl/nanumgothic/<파일>?ref=<커밋>`

앱이 쓰는 Manrope의 출처는 `docs/design-system.md` "스냅샷의 글꼴" 표에 있다.

**한계**: 글꼴 파일은 앱과 스냅샷이 같지만 래스터화는 OS마다 다르다. 스냅샷의 한글 픽셀이 기기와 같다는 뜻은 아니다.
