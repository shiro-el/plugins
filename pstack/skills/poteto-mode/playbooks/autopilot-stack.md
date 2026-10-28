### Autopilot-stack

Run the Autopilot-full playbook, but do not merge.

1. **In place of step 5, stop at verified.** Stop when each PR is verified and green at its current head, then hand the PRs to the operator. After the handoff, nobody pushes without the operator's go. Every loop tick prompt names this file, so each tick sees the no-merge rule.
2. **Stack a PR only when it builds on another PR.** This is the one exception to Autopilot-full step 3, and step 3 below says which dependencies count. Base the PR on the other PR's branch in place of trunk, per **Size and stacks** in `playbooks/opening-a-pr.md`. In place of step 2's rebase onto trunk, each PR rebases onto its parent PR's branch, and the stack root rebases onto trunk. A new head on the lower PR restacks the PRs above it, and a PR whose `git patch-id` the restack leaves unchanged keeps its verdict.
3. **Classify every dependency before you spawn, and stack only on code.** A queue's "blocked by" links mix three kinds of dependency, and only one of them needs a stack. Log each edge's class as a decision row.
   - `code`: the child calls, reads, or extends code the parent adds. Stack it per step 2.
   - `file`: both PRs change the same files, a generated file, or an ordered sequence such as migrations, but neither needs the other's code. Run both off trunk in parallel. Whichever lands second rebases at merge prep, regenerates generated files instead of hand-merging them, and moves its ordered entries after the ones already on trunk.
   - `order`: the order is only how the plan reads. Run both off trunk in parallel.

   A serial chain of `file` and `order` edges is the plan's shape, not the work's, so most of the queue can start at once.
4. **Start a child early only on a frozen interface.** A child may start on its parent's code-ready head before the parent's verdict, when its brief names the parent interface it uses, such as a function signature, a schema, or an API contract. If a parent fix round changes that interface, hold the child until the parent is clean. If it does not, the child only restacks. The child computes its own restack from its merge-base (`git rebase --onto <new parent head> <old parent head>`) and never takes the old head from a message, because the root can name the wrong one.
5. **Budget the machine before you spawn.** Each owner and each verifier lane that runs the app holds an isolated local environment, such as a worktree with its own databases, ports, and container networks, so one PR under verification can hold three. Before each spawn, count what the machine has free, such as the repo's slot allocator, container networks, and memory, and keep the agents in flight within it. When capacity runs short, the lowest unverified PR in each stack goes first. Every agent stops its environment when its turn ends, keeping its data, and touches no container, network, volume, or process it did not create, even an idle one, without the operator's go.

**Reply:** list each PR with its verdict, in place of what merged.
