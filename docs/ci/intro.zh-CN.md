
本项目使用 [Travis CI](https://travis-ci.org/) 作为 CI 服务,
当前的 [build 状态](https://travis-ci.org/coderplanets/coderplanets_server) 在
README 中由 [![Build
Status](https://travis-ci.org/coderplanets/coderplanets_server.svg?branch=dev)](https://travis-ci.org/coderplanets/coderplanets_server)
表示, 并随着每一次 `commit push` 或 `PR` 代码合并触发并更新。

CI 不仅仅是运行测试，它还会触发以下任务：

- [x] 确保所有的测试运行并通过
- [x] 确保测试覆盖率更新
- [x] 发布 GraphQL-Schema 到 apollo-engine
- [x] 确保 GraphQL-Schema 可用
- [x] 确保 commit messages 符合规定
- [x] 如果 build 失败发送邮件给相关开发者
