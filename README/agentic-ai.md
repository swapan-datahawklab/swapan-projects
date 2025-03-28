AIOPSLAB, an innovative framework for building AgentOps benchmarks to
evaluate LLM-based AIOps agents


two microservice applications from DeathStarBench
    HotelReservation
    SocialNetwork

    The SocialNetwork 
    application has 28 microservices, including Memcached, MongoDB, and Redis, that together implement
    several features of real-world social networking applications

    The HotelReservation application, implemented with Go and gRPC, supports services like recommending and reserving hotels


An extensible fault library, integrated with ChaosMesh
A telemetry observer, 
    Prometheus for metrics
    Jaeger for tracing
    Filebeat and logstash for logging
`   supports on-disk storage of telemetry
    supports on-disk storage of telemetry data, facilitating evaluations of both traditional AIOps algorithms and agentic solution
`   We also integrate Helm and Kubernetes APIs into the AIOPSLAB’s orchestrator

Agent client interface:
(1) the set of valid actions available to the agent 
(2) how the service’s state is conveyed back to the agent as the observation of its actions

Some API's provided by AIOPSlab
get_logs
get_metrics
get_traces
exec_shell

other interfaces;
Problem Initializers
Problem Evaluatorst
    Time-to_Detect
    number of steps taken
    tokens produced

Our only requirement is that the agent
must implement a get_action method with the following
signature: async def get_action(state: str)-> str.
It takes the service’s state as input from the Orchestrator
and returns the next action the agent wants to take. Note
that this could be a simple wrap







AI-driven tools and benchmarks
WebArena
LiveCodeBench
SWE-bench

Workload generator:
wrk2

Agents evaluated
GPT-3.5-TURBO and GPT-4-TURBO only have access to secure shell
React
    uses chain of thought reasoning
Flash
    employs a workflow automation system that monitors execution status
    and decomposes complex instructions into manageable,
    conditional segments. It incorporates hindsight generation to learn from past interactions. As FLASH was not
    publicly available at the time of writing, we develop a
    simplified version that retrospectively generates insights
    after each step

non-LLM-based AIOps algorithms on AIOPSLAB, using (multi-modal) telemetry data as input
MKSMC
    for detection
RM-LAD and PDiagnose for localization

We select the “user-service”, “text-service”, and
“post-storage-service” from SocialNetwork as injection
targets. Injecting faults into different targets is crucial
because each service may have distinct dependencies

the need for (1) better task
decomposition for AIOps problems using planning, (2)
improved feedback mechanisms for intermediate steps,
and (3) solutions that go beyond environment feedback
and self-repair.

The get_logs API is the most frequently
used API across all agent

Wasting steps on unnecessary actions
Overloaded information when consuming data

Agents tend to use get_metrics and get_traces APIs
sparingly in successfully resolved problems

This is understandable, as the metrics data, e.g., CPU and memory usage have numerous
values, which are hard to directly interpret, and trace
data are descriptive records of the system’s dependencies, which are more comprehensible when visualized
However, agents may subsequently consume these data
with a cat command directly, which can overwhelm the
model’s input context window and cause distraction and
more tokens to be consumed

We expect more refined
telemetry data processing and filtering mechanisms to
be implemented in the agents to avoid this issue in the
future.
3.6.3 I

We notice that agents can struggle with improper formatting of API calls. 

he REACT agent occasionally
generates incorrect API commands, but typically recovers by reasoning through the errors and self-correcting its
commands

AgentOps
    fine-tuned GPT models
        RCACopilot
        RCAgent
        MonitorAssistant
        Xpert

there is a notable gap: the absence of a unified benchmark capable of providing realistic evaluation scenarios
to assess agents’ performance across operational tasks