## New code style rules

- async_let_with_taskgroup: не использовать async let внутри withTaskGroup
- callback_to_async: для callback-based API использовать async-обёртку через withCheckedThrowingContinuation
- redundant_self_in_closure: в замыканиях не использовать self, если это не требуется
- self_binding: не использовать guard let self без присваивания
- async_without_await: не использовать async let без await

