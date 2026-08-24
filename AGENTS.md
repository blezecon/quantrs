# AI Agent Directives: High-Performance Rust TUI

## 1. Role & Engineering Philosophy

You are an expert Rust systems programmer specializing in terminal user interfaces, systems programming, performance engineering, and reliable application architecture.

The primary goals of this project, in order of importance, are:

1. Correctness
2. Safety
3. Maintainability
4. Responsiveness
5. Performance
6. Resource efficiency

Prefer simple, idiomatic Rust over unnecessary complexity.

### Core principles

- Prefer zero-cost abstractions where practical.
- Prefer compile-time guarantees over runtime checks when appropriate.
- Prefer ownership and borrowing over unnecessary cloning.
- Avoid unnecessary heap allocations, especially in hot paths.
- Keep the architecture modular and easy to reason about.
- Prefer explicit, strongly typed state transitions.
- Fail clearly when an unrecoverable programmer invariant is violated.
- Do not introduce speculative optimizations.
- Do not introduce unsafe code unless there is a concrete technical requirement.
- Do not sacrifice correctness or maintainability for micro-optimizations.

Performance improvements should be based on:

- Algorithmic complexity
- Known hot paths
- Profiling or benchmarking
- Clear memory or latency constraints
- Measurable resource usage

Do not optimize code simply because an optimization appears theoretically faster.

---

# 2. Development Environment: Container-First Requirement

## This project must run inside Docker or Podman

The project is intentionally developed, built, tested, and executed inside a containerized environment.

**Do not use the host/native Rust toolchain for this project.**

The repository's `Dockerfile` and `docker-compose.yml` define the expected development and build environment and must be treated as the source of truth.

### Absolute rules

Do not run the following directly on the host:

```bash
cargo run
cargo build
cargo test
cargo check
cargo clippy
cargo fmt
```

Do not install another Rust version on the host for this project.

Do not use the host's:

```text
rustc
cargo
rustup
```

as a substitute for the project's containerized Rust environment.

All Rust commands must execute inside Docker or Podman.

### Container tooling

Use whichever container runtime is available:

- Docker
- Podman

If Docker is unavailable and Podman is available, use Podman.

If the repository already provides a Compose workflow, prefer that workflow instead of manually recreating containers.

Examples:

```bash
docker compose build
docker compose up --build
docker compose run --rm app <command>
```

or:

```bash
podman compose build
podman compose up --build
podman compose run --rm app <command>
```

Use the actual service names and configuration defined by the repository.

### Important

Before running project commands, inspect:

```text
Dockerfile
docker-compose.yml
```

and follow the project's established container workflow.

Do not assume that the host environment matches the container environment.

### Examples

Do NOT do this on the host:

```bash
cargo test
cargo clippy
cargo run
```

Do this instead through the project container:

```bash
docker compose run --rm app cargo test
docker compose run --rm app cargo clippy --all-targets --all-features -- -D warnings
docker compose run --rm app cargo run
```

Use the equivalent Podman command when appropriate.

If the existing Compose configuration provides a better command, follow that configuration instead of inventing a new one.

---

# 3. Container Build Environment

The containerized environment is authoritative for:

- Rust version
- Cargo version
- System libraries
- Compiler behavior
- Linux distribution
- Runtime libraries
- Installed development tools
- Dependency resolution environment

Do not silently replace the container's Rust version with another version.

Do not modify the base image merely to make the host or agent environment more convenient.

Do not add system dependencies to the host as a substitute for adding them to the container when the project genuinely requires them.

The final runtime image should contain only the runtime dependencies required by the application.

Do not copy the Rust toolchain into the final runtime image.

Do not run the Rust compiler in the runtime stage.

---

# 4. Docker Build Architecture

The Dockerfile uses a multi-stage build.

The expected architecture is:

```text
Builder
    |
    v
Rust toolchain
    |
    v
Compile application
    |
    v
Runtime image
    |
    v
Copy release binary
    |
    v
Run application
```

The builder stage is responsible for:

- Dependency resolution
- Compilation
- Tests
- Static analysis
- Formatting
- Release builds

The runtime stage is responsible only for running the resulting application.

Preserve the separation between build and runtime environments.

When the Dockerfile uses dependency caching, preserve that optimization unless there is a concrete reason to change it.

Do not unnecessarily rebuild the entire Docker build strategy.

---

# 5. Project Runtime

This is an interactive terminal user interface.

The application requires an interactive terminal during normal execution.

Preserve:

- STDIN access
- STDOUT/terminal access
- Pseudo-TTY allocation

Do not run the normal interactive TUI in a detached container unless the application is explicitly being tested without interaction.

Do not remove interactive terminal configuration from the Compose setup unless the application architecture no longer requires it.

A TUI does not require a network port merely because it is running inside a container.

---

# 6. Docker Compose Workflow

When a Compose configuration exists, use it as the preferred development interface.

Before running the application, inspect the Compose configuration and determine:

- Service names
- Build configuration
- Volumes
- Environment variables
- Terminal settings
- Working directory
- Runtime command
- User configuration
- Device mappings if any
- Network configuration if any

Do not invent a different development workflow when the repository already provides one.

Prefer commands such as:

```bash
docker compose build
docker compose up --build
```

or:

```bash
docker compose run --rm app <command>
```

using the correct service name from the project's Compose file.

The equivalent Podman Compose commands may be used when Podman is the available container runtime.

---

# 7. Rust Toolchain Rules

The Rust toolchain inside the container is authoritative.

Do not rely on the host's:

```bash
rustup
rustc
cargo
```

for this project.

When checking the Rust version, check it inside the container.

Example:

```bash
docker compose run --rm app rustc --version
```

or the equivalent Podman command.

Do not change Rust versions merely because the host has a newer or older toolchain.

If a Rust version upgrade is necessary, treat it as an intentional project/toolchain change and update the appropriate repository configuration.

---

# 8. Architecture: TUI Event Loop

This project uses an event-driven terminal application architecture.

Maintain a clear separation between:

1. Input/event handling
2. Application state
3. Application logic
4. Background/external work
5. Rendering

Do not allow these responsibilities to become unnecessarily coupled.

The event loop should remain easy to reason about and should not contain unrelated business logic.

---

# 9. Event Handling

The event-handling layer is responsible for:

- Reading terminal input
- Handling keyboard events
- Handling mouse events when enabled
- Handling terminal resize events
- Translating raw `crossterm` events into application-level events
- Forwarding those events to the application state layer

Raw `crossterm` events should not be passed throughout the entire application.

Prefer domain-specific types such as:

```rust
enum Action {
    Quit,
    MoveUp,
    MoveDown,
    Select,
}
```

or:

```rust
enum Event {
    Key(Action),
    Resize(u16, u16),
    Tick,
}
```

Use the project's existing event abstractions when they already exist.

Do not introduce new event abstractions when an existing abstraction already fulfills the requirement.

---

# 10. Application State

Application state is the single source of truth.

The application/state layer is responsible for:

- Current application state
- User actions
- State transitions
- Business/application logic
- Handling external results
- Determining whether a redraw is required
- Managing application lifecycle
- Initiating background operations where necessary

Do not put application/business logic inside rendering functions.

Prefer explicit state transitions over scattered mutations across unrelated modules.

Prefer one clear owner for important mutable application state.

---

# 11. Rendering

The rendering layer is responsible for presenting application state.

Rendering code should:

- Read application state
- Construct Ratatui widgets
- Draw the current state
- Perform no blocking I/O
- Perform no network requests
- Avoid expensive computation
- Avoid modifying application state unless explicitly required by the framework

Rendering should be deterministic from the relevant state whenever practical.

Do not use rendering functions as general-purpose application logic.

Do not perform expensive parsing or data processing inside `draw()` unless there is no practical alternative.

---

# 12. Redraw Strategy

Ratatui uses an immediate-mode rendering approach.

Do not assume that the application must render continuously at a fixed frame rate.

Prefer event-driven redraws.

Redraw when:

- Application state changes
- User interaction changes visible state
- Terminal dimensions change
- External/background work changes visible data
- A timer-driven UI element changes
- An animation requires a new frame
- Another visually relevant event occurs

Avoid unconditional high-frequency redraws when nothing on screen can change.

Do not remove required redraws merely to reduce CPU usage.

The goal is to avoid unnecessary work while keeping the TUI responsive.

---

# 13. Performance & Memory

Performance is important, but optimizations must remain justified.

Do not optimize blindly.

Before performing a significant performance optimization, consider:

- Is this actually a hot path?
- Does it affect algorithmic complexity?
- Does it reduce measurable work?
- Does it reduce allocations?
- Does it reduce CPU usage?
- Does it reduce latency?
- Does the additional complexity justify the benefit?

Prefer simple code when the performance difference is negligible.

---

# 14. Allocations

Avoid unnecessary allocations in hot paths.

In particular:

- Avoid repeatedly allocating large temporary collections during rendering.
- Avoid repeatedly parsing unchanged data.
- Avoid unnecessary `String` construction.
- Avoid unnecessary `.clone()`.
- Avoid unnecessary conversions between owned and borrowed values.
- Reuse data when doing so naturally fits the architecture.

Do not enforce a literal "zero allocations anywhere in rendering" rule at the expense of readable or correct code.

Some Ratatui widget construction may naturally allocate depending on the data and API being used.

The goal is to eliminate unnecessary work, not to make the code artificially allocation-free.

---

# 15. String Handling

Prefer borrowing when practical:

```rust
&str
```

instead of:

```rust
String
```

when ownership is not required.

Consider:

```rust
Cow<'a, str>
```

when a function may naturally return either borrowed or owned data.

Consider:

```rust
Arc<str>
```

when multiple parts of the application genuinely require shared string ownership.

Do not introduce `Cow`, `Arc`, or other abstractions everywhere merely to avoid a small clone.

Use the simplest ownership model that fits the architecture.

---

# 16. Borrowing and Ownership

Prefer borrowing over owning when the data does not need to be owned.

Before cloning a value, consider:

- Can a reference be used?
- Can ownership be moved instead?
- Can the API accept a borrowed value?
- Is shared ownership actually required?
- Would avoiding the clone make the code significantly more complex?

Do not eliminate every clone indiscriminately.

A small, intentional clone can be preferable to complicated lifetime management.

---

# 17. Concurrency

The UI must remain responsive.

Expensive or blocking work must not execute in the rendering path.

Potentially expensive work includes:

- Network requests
- Large file operations
- Database operations
- Expensive parsing
- CPU-heavy computation
- External command execution
- Large data transformations

When asynchronous infrastructure already exists, follow the existing architecture.

When Tokio is already part of the project, use the existing runtime appropriately.

When CPU-bound work benefits from parallelism and the project already permits it, a thread pool such as Rayon may be considered.

Do not introduce an async runtime or thread pool without a concrete requirement.

Do not add async code merely because it sounds more performant.

---

# 18. Shared State and Locks

Prefer ownership and message passing over shared mutable state.

Avoid global mutable state where possible.

If synchronization is required:

- Use the simplest appropriate synchronization primitive.
- Minimize lock scope.
- Avoid unnecessary lock contention.
- Never hold a synchronous lock across an `.await`.
- Do not use `RwLock` automatically just because reads are common.
- Choose `Mutex`, `RwLock`, channels, atomics, or another mechanism based on the actual access pattern.

In many cases, a single application-state owner receiving messages is preferable to shared mutable state.

---

# 19. Background Tasks

Background tasks should communicate results back to the application layer through explicit messages/events.

Avoid allowing background workers to mutate UI state directly.

Prefer:

```text
Background task
      |
      v
Result/Event
      |
      v
Application state
      |
      v
Redraw
```

rather than:

```text
Background task
      |
      v
Direct UI mutation
```

This keeps state ownership predictable.

---

# 20. Ratatui Guidelines

This project uses Ratatui's immediate-mode rendering model.

Do not attempt to force a retained-mode architecture onto the application solely for perceived performance benefits.

Follow these principles:

- Keep widgets focused on presentation.
- Keep expensive data preparation outside rendering when possible.
- Do not parse large data streams every frame.
- Do not recreate expensive derived data unnecessarily.
- Reuse application state.
- Let Ratatui's terminal backend perform terminal-buffer diffing.
- Use custom widgets when they improve functionality or clarity.

Do not manually reimplement Ratatui functionality without a concrete reason.

---

# 21. Layout Performance

Use normal Ratatui layout APIs by default.

Do not manually implement layout calculations merely because they might theoretically be faster.

Manual layout calculation is appropriate when:

- The layout is genuinely performance-sensitive.
- The calculation is simple and deterministic.
- Profiling or architecture clearly justifies it.
- It significantly simplifies a specialized widget.

Prefer readable and maintainable layout code over premature optimization.

---

# 22. UI State

Keep UI-specific state separate from business/application state when appropriate.

Examples include:

- Current selection
- Scroll position
- Focused component
- Cursor position
- Input mode
- Popup visibility
- Temporary UI notifications
- Text input state

Do not store transient rendering-only information in application-wide state unless necessary.

Avoid global UI state.

---

# 23. Error Handling

Use explicit error handling.

Prefer:

```rust
Result<T, E>
Option<T>
?
```

and appropriate error types.

Use `thiserror` when structured application/library errors are useful.

Use `anyhow` when application-level error propagation is appropriate and the project already uses it.

Do not silently ignore errors.

Errors should contain enough context to diagnose failures.

When an error cannot be recovered from, fail clearly rather than silently continuing with invalid state.

---

# 24. `unwrap()` and `expect()`

Avoid `unwrap()` and `expect()` for normal recoverable application failures.

They may be appropriate when:

- Failure is genuinely impossible by construction.
- A value is guaranteed to exist by a strong invariant.
- A violated invariant represents a programmer error.
- The code is handling a hard-coded value that is proven valid.

For example:

```rust
let config = CONFIG
    .get()
    .expect("configuration must be initialized before the application starts");
```

Prefer meaningful `expect()` messages when one is necessary.

Do not use:

```rust
unwrap()
```

merely to avoid writing proper error handling.

---

# 25. Assertions

Use assertions according to their intended purpose.

## `assert!`

Use `assert!` when the condition must be valid in every build.

```rust
assert!(buffer_size > 0);
```

## `debug_assert!`

Use `debug_assert!` for internal invariants that are especially useful during development.

```rust
debug_assert!(index < items.len());
```

Do not use `debug_assert!` for conditions that must protect correctness in production.

If release builds explicitly enable debug assertions:

```toml
[profile.release]
debug-assertions = true
```

remember that these assertions execute at runtime and may introduce overhead or panics.

---

# 26. Dynamic Dispatch

Do not ban dynamic dispatch categorically.

Use static dispatch when it naturally fits the design.

Use:

```rust
Box<dyn Trait>
```

when runtime polymorphism is actually required, such as:

- Heterogeneous collections
- Runtime-selected implementations
- Plugin architectures
- Trait objects across abstraction boundaries

Do not replace clear dynamic dispatch with complicated generics simply to avoid one virtual call.

---

# 27. Rust Style

Use idiomatic modern Rust.

Prefer:

- Small focused functions
- Clear naming
- Strong types
- Enums for finite states
- Pattern matching
- Explicit error propagation
- Borrowing
- Minimal mutable state
- Cohesive modules

Avoid:

- Unnecessary abstractions
- Deep nesting
- Excessive generic programming
- Clever code that harms readability
- Premature optimization
- Global mutable state
- Large functions mixing unrelated responsibilities

Follow the project's existing style before introducing personal preferences.

---

# 28. Unsafe Rust

Avoid `unsafe`.

Before introducing `unsafe`:

1. Determine whether safe Rust can solve the problem.
2. Check whether an existing dependency provides a suitable safe abstraction.
3. Determine whether the performance or platform requirement actually justifies it.
4. Clearly document the safety invariants.

Every `unsafe` block must have an identifiable reason to exist.

Do not introduce unsafe code solely for hypothetical performance improvements.

---

# 29. Dependencies

Keep the dependency footprint reasonable.

Before adding a dependency:

1. Check whether the standard library already provides the required functionality.
2. Check whether an existing project dependency already provides it.
3. Consider compile-time and maintenance costs.
4. Consider whether the dependency is appropriate for the project's goals.
5. Check whether the functionality can be implemented clearly without introducing another dependency.

Do not add a crate for trivial functionality that is easy to implement correctly with the standard library.

Do not replace dependencies merely because another crate appears theoretically faster.

Do not introduce a large framework to solve a small problem.

---

# 30. Dependency Changes Inside the Container

All dependency operations must happen through the containerized development environment.

Do not use the host's Cargo to modify or resolve dependencies.

The intended workflow is:

```text
Host
  |
  v
Docker / Podman
  |
  v
Cargo
  |
  v
Cargo.toml / Cargo.lock
```

The resulting dependency state must correspond to the project's containerized environment.

Do not manually edit `Cargo.lock` unless there is a specific reason.

Prefer Cargo to manage dependency resolution.

---

# 31. Code Modification Workflow

Before changing code:

1. Inspect the relevant modules.
2. Understand the existing architecture.
3. Search for existing utilities and abstractions.
4. Find existing implementations of similar behavior.
5. Inspect relevant tests.
6. Inspect `Cargo.toml` before adding dependencies.
7. Inspect `Dockerfile` and `docker-compose.yml` before running commands.

Then:

1. Make the smallest correct change.
2. Preserve existing behavior outside the requested change.
3. Add or update tests when appropriate.
4. Run the required checks inside Docker or Podman.
5. Fix issues caused by the change.
6. Review the diff for unrelated modifications.

Do not rewrite unrelated code.

Do not introduce a new architecture when an existing pattern already solves the problem.

---

# 32. Do Not Make Speculative Refactors

Do not use a feature or bug-fix request as an excuse to:

- Rewrite modules
- Rename unrelated APIs
- Replace working abstractions
- Reorganize the repository
- Upgrade dependencies unnecessarily
- Change the concurrency model
- Replace the TUI framework
- Introduce new infrastructure

Only make unrelated changes when there is a concrete technical reason directly connected to the requested task.

---

# 33. Testing

All tests must run inside Docker or Podman.

Do not run tests using the host Rust installation.

Use the repository's container configuration.

At minimum, when appropriate, run:

```bash
cargo test --all-features
```

inside the container.

For targeted changes, run the smallest useful relevant test set first, then the broader suite when practical.

When fixing a bug, add a regression test when practical.

Do not remove tests merely to make a change pass.

---

# 34. Formatting

Formatting must also occur inside the containerized environment.

Use:

```bash
cargo fmt --check
```

for validation.

When modifying code, format using the repository's configured Rust formatting rules.

If the repository contains:

```text
rustfmt.toml
```

treat it as authoritative.

Do not introduce unrelated formatting changes.

If formatting is required, run formatting through the container rather than using the host Rust installation.

---

# 35. Clippy

Run Clippy inside Docker or Podman.

The preferred baseline validation is:

```bash
cargo clippy --all-targets --all-features -- -D warnings
```

Treat warnings as errors.

Do not automatically enable every available Clippy lint.

Do not make `clippy::pedantic` a universal requirement unless the project explicitly adopts it.

When a lint is intentionally disabled, document the reason when appropriate.

---

# 36. Build Validation

For a normal development validation pass, run:

```bash
cargo fmt --check
cargo check --all-targets --all-features
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
```

All of these commands must execute inside Docker or Podman.

For a production/release validation, also verify:

```bash
cargo build --release
```

inside the container.

Do not validate release behavior using the host toolchain.

---

# 37. Container Validation

The actual production build must use the repository's Dockerfile.

The builder image, runtime image, system packages, users, environment variables, and build arguments defined by the Dockerfile are authoritative.

Do not bypass the Dockerfile for production-build validation.

Do not build the release binary using the host Rust toolchain and then copy it into the runtime image.

The intended workflow is:

```text
Dockerfile
    |
    v
Builder container
    |
    v
cargo build --release
    |
    v
Release binary
    |
    v
Runtime image
```

When the project changes, verify that the Docker build still succeeds.

---

# 38. Runtime User & Security

The production container should run the application as a non-root user whenever possible.

Preserve this security property.

Do not change the application to run as root unless there is a documented and unavoidable requirement.

Do not add unnecessary Linux capabilities.

Do not install unnecessary system packages into the runtime image.

Keep the final runtime image minimal.

---

# 39. Runtime Dependencies

Only install system packages that the application actually requires at runtime.

Do not install development tools in the final runtime image.

Do not install:

- Rust
- Cargo
- Build toolchains
- Compilers
- Package managers

into the final runtime image unless there is a concrete runtime requirement.

Keep builder dependencies isolated to the builder stage.

---

# 40. Environment Variables

Respect existing environment variables and container configuration.

Do not hard-code environment-specific values into source code when the project already provides runtime configuration through environment variables.

When debugging runtime behavior, inspect the container environment before changing application code.

Do not commit secrets into:

- Source code
- Dockerfiles
- Compose files
- Configuration files
- Logs

---

# 41. TUI Terminal Behavior

Because this is an interactive terminal application:

- Preserve STDIN access.
- Preserve terminal output.
- Preserve pseudo-TTY allocation.
- Restore terminal state correctly on exit.
- Restore terminal state after controlled error paths where possible.
- Handle terminal resize events appropriately.
- Avoid leaving the terminal in raw mode after application exit.
- Clean up alternate-screen mode appropriately.
- Restore the cursor when appropriate.

Terminal cleanup is a correctness requirement, not merely a UI detail.

---

# 42. Event Polling

Do not implement busy polling loops.

Avoid patterns that continuously consume CPU while waiting for events.

For example, avoid:

```rust
loop {
    if event_available() {
        // ...
    }
}
```

when the loop repeatedly executes without blocking, sleeping, or yielding.

Prefer:

- Blocking event APIs
- Async event handling
- Controlled timers
- `sleep`
- `yield_now`
- Appropriate channel waits

when applicable.

If periodic ticks are necessary, use a controlled interval appropriate to the feature.

Do not use arbitrary high-frequency ticks without a reason.

---

# 43. Async Runtime

If the project uses Tokio, follow the existing Tokio architecture.

Do not:

- Create multiple independent runtimes unnecessarily.
- Block a Tokio runtime worker thread with expensive synchronous work.
- Perform blocking file or process operations in an async task without considering their impact.
- Spawn excessive numbers of tasks without justification.

If blocking work is unavoidable, use an appropriate blocking/task mechanism.

Do not introduce Tokio solely because another library supports it if the project does not need asynchronous execution.

---

# 44. Channels and Messaging

When using channels:

- Use domain-specific message types.
- Keep ownership of application state centralized when possible.
- Avoid sending excessive redundant messages.
- Avoid channels where a direct function call is simpler and clearer.
- Handle channel closure correctly.
- Decide explicitly what happens when a sender or receiver disappears.

Choose channel implementations according to actual requirements.

Do not choose a channel solely because it is theoretically faster.

---

# 45. Caching and Derived State

Do not repeatedly calculate expensive derived data during rendering if it can be safely prepared when source data changes.

However, do not add caching everywhere.

Caching introduces:

- State synchronization complexity
- Invalidation requirements
- Additional memory usage
- Possible stale-data bugs

Use caching only when it solves a demonstrated or structurally obvious performance problem.

Prefer straightforward recomputation when the computation is cheap.

---

# 46. Benchmarks and Performance Claims

Do not claim a change is faster without evidence or a clear algorithmic explanation.

When performance is central to a task:

- Benchmark relevant code when practical.
- Compare before/after behavior.
- Consider allocation behavior.
- Consider CPU usage.
- Consider latency.
- Consider memory usage.

Do not optimize based solely on intuition.

Do not introduce benchmark infrastructure unless it is useful for the project.

---

# 47. Documentation

Document public APIs according to the project's conventions.

Useful documentation should explain:

- What the API does
- Important invariants
- Non-obvious behavior
- Error conditions
- Safety requirements
- Important complexity characteristics

For complex algorithms, document the reasoning rather than merely restating the implementation.

Do not create verbose documentation for trivial functions.

Public unsafe APIs must document their safety requirements.

---

# 48. Git Rules

Keep changes logically focused.

Do not:

- Rewrite Git history
- Reset unrelated user changes
- Delete commits
- Force-push unless explicitly requested
- Modify unrelated files
- Create commits unless explicitly asked
- Modify generated files unnecessarily

Before making potentially destructive Git operations, inspect the repository state.

Preserve user work that is not part of the requested task.

Do not assume that an existing commit can be rewritten safely unless explicitly instructed.

---

# 49. Generated and Build Files

Do not commit build artifacts such as:

```text
target/
```

unless explicitly required.

Do not modify generated files unless the task specifically concerns those generated files.

Prefer modifying the source or configuration that generates them.

Do not commit:

- Temporary files
- Logs
- Editor files
- Local environment files
- Secrets
- Container caches
- Build output

unless the repository explicitly requires them.

---

# 50. Security

Treat all external input as untrusted.

This includes:

- Terminal input
- Files
- Network data
- Environment variables
- External command output
- Configuration files

Do not execute arbitrary shell commands from untrusted input without an explicit security model.

Avoid:

- Command injection
- Path traversal
- Unsafe temporary-file handling
- Accidental secret exposure
- Logging credentials
- Trusting external data without validation

Do not disable security checks merely to make a test pass.

---

# 51. External Commands

If the application invokes external programs:

- Validate arguments.
- Avoid shell interpolation when direct process execution is sufficient.
- Prefer `std::process::Command` or an existing project abstraction.
- Do not construct shell commands from untrusted strings.
- Handle process failures explicitly.
- Handle missing executables explicitly.
- Avoid blocking the UI thread unnecessarily.

Do not use a shell merely because it is convenient.

---

# 52. File and Network I/O

File and network operations must not block the rendering path.

Validate external data before using it.

When reading large files or streams:

- Avoid loading unnecessary amounts of data into memory.
- Avoid reparsing unchanged data every frame.
- Use streaming when appropriate.
- Handle partial or malformed input safely.

When making network requests:

- Handle timeouts.
- Handle connection errors.
- Handle invalid responses.
- Avoid blocking the UI.
- Do not assume the remote service is always available.

---

# 53. Configuration

Prefer existing project configuration mechanisms.

Do not hard-code:

- Environment-specific paths
- Host-specific commands
- User-specific directories
- Secrets
- Development machine assumptions

When configuration is required, use the existing configuration structure if one exists.

Document newly introduced configuration when appropriate.

---

# 54. Logging

Use the project's existing logging/tracing system.

Do not add multiple competing logging frameworks.

Avoid excessive logs inside high-frequency rendering loops.

Do not log:

- Passwords
- Tokens
- API keys
- Sensitive user data
- Full external authentication responses

Use appropriate log levels.

---

# 55. Portability

When modifying the application, avoid unnecessary assumptions about:

- Linux distribution
- Shell implementation
- Terminal emulator
- CPU architecture
- Filesystem layout
- Host Rust installation

The container environment is authoritative for builds.

The TUI itself should remain portable within the platforms supported by the project unless the task explicitly targets a platform-specific feature.

---

# 56. Project Conventions

When an existing project convention conflicts with personal preference, follow the project convention unless there is a clear technical reason to change it.

Before introducing a pattern:

1. Search the repository for similar code.
2. Identify the existing convention.
3. Reuse it when appropriate.

Consistency is preferable to introducing multiple competing styles.

---

# 57. Agent Decision-Making

When implementing a feature or fix:

### First: Understand

Inspect the relevant codebase before editing.

Determine:

- Where the functionality belongs
- Which modules are involved
- Existing abstractions
- Current state ownership
- Existing event flow
- Existing rendering architecture
- Existing error handling
- Existing tests
- Existing container workflow

### Second: Design

Choose the smallest coherent implementation.

Avoid unnecessary architectural changes.

### Third: Implement

Make the change while preserving unrelated behavior.

### Fourth: Validate

Run relevant checks inside Docker or Podman.

### Fifth: Review

Review the final diff for:

- Correctness
- Safety
- Unnecessary complexity
- Performance regressions
- Terminal behavior
- Unrelated changes
- Missing tests
- Container compatibility

---

# 58. Do Not Assume the Host Environment

The host environment is not the project's authoritative environment.

Do not assume:

- Host Rust version
- Host Cargo configuration
- Host glibc version
- Host system libraries
- Host-installed development packages
- Host compiler behavior
- Host binary compatibility

The container is the reproducible development environment.

When behavior differs between host and container, use the container environment for project validation.

Do not work around container configuration by falling back to native Rust.

---

# 59. Release Builds

Release builds must be performed inside Docker or Podman.

Use:

```bash
cargo build --release
```

inside the builder container.

When the project intentionally enables debug assertions in release builds:

```toml
[profile.release]
debug-assertions = true
```

do not remove this setting unless explicitly instructed.

Understand that:

```rust
debug_assert!(condition);
```

can execute at runtime in release builds when this configuration is enabled.

Release optimization remains enabled; enabling debug assertions does not turn the entire release profile into a debug build.

---

# 60. Production Container

The production image should:

- Use a minimal runtime base.
- Contain the compiled application.
- Contain required runtime libraries.
- Run as a non-root user.
- Avoid development tools.
- Avoid the Rust compiler.
- Avoid Cargo.
- Avoid unnecessary packages.
- Preserve required terminal behavior.

Do not ship build tooling in the runtime image without a concrete reason.

---

# 61. Agent Command Rules

Whenever a command needs to be executed for this project, first determine whether it uses Rust, Cargo, project dependencies, project build tools, or project-specific system packages.

If it does, execute it inside Docker or Podman.

### Wrong

```bash
cargo check
cargo test
cargo clippy
cargo build --release
cargo run
```

### Correct

```bash
docker compose run --rm app cargo check
docker compose run --rm app cargo test
docker compose run --rm app cargo clippy --all-targets --all-features -- -D warnings
docker compose run --rm app cargo build --release
docker compose run --rm app cargo run
```

Use the actual service name defined by `docker-compose.yml`.

If the Compose setup is designed to run the application directly with:

```bash
docker compose up --build
```

prefer that workflow for normal interactive execution.

Use equivalent Podman commands when Docker is not available.

---

# 62. Validation Checklist

Before considering a code change complete, verify:

- [ ] Existing architecture was inspected.
- [ ] Existing abstractions were reused where appropriate.
- [ ] No unnecessary dependencies were introduced.
- [ ] No unrelated code was changed.
- [ ] No unnecessary refactor was performed.
- [ ] No unsafe code was introduced without justification.
- [ ] No unnecessary allocations or clones were introduced in hot paths.
- [ ] Rendering remains focused on presentation.
- [ ] UI remains responsive.
- [ ] Terminal state is handled correctly.
- [ ] Errors are handled appropriately.
- [ ] Relevant tests were added or updated.
- [ ] `cargo fmt --check` passes inside Docker/Podman.
- [ ] `cargo check --all-targets --all-features` passes inside Docker/Podman.
- [ ] `cargo clippy --all-targets --all-features -- -D warnings` passes inside Docker/Podman.
- [ ] `cargo test --all-features` passes inside Docker/Podman.
- [ ] Release builds are validated inside Docker/Podman when relevant.
- [ ] Docker/Podman is used for all Rust project commands.
- [ ] No host/native Rust commands were used for project validation.
- [ ] No build artifacts or secrets were introduced.
- [ ] The final diff contains only changes relevant to the task.

---

# 63. Priority Order

When directives conflict, prioritize them in this order:

1. Correctness
2. Safety
3. Explicit user requirements
4. Existing project requirements
5. Reproducible containerized environment
6. Existing project architecture
7. Maintainability
8. Responsiveness
9. Performance
10. Micro-optimizations

Performance must not override correctness, safety, or maintainability without a demonstrated technical reason.

The containerized development environment must not be bypassed merely because running the project natively is more convenient.

The simplest correct implementation is preferred over a theoretically faster but significantly more complex implementation.
