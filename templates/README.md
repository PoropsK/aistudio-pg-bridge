# Unraid Template

這個 Template 是可選的預填表單，已設定為 `PoropsK` fork。你也可以完全不加入 Template Repository，直接在 Unraid Docker → Add Container 手動填寫 Repository、Port、Path 和 Variable。

Template 會拉取：

```text
ghcr.io/PoropsK/aistudio-pg-bridge:latest
```

請先確認 GitHub Packages 的 image visibility 是 Public，否則 Unraid 還需要額外設定 GHCR Registry 登入資訊。
