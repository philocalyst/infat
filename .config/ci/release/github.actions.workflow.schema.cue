package release

import (
	"struct"
	"strings"
)

#Workflow: {
	@jsonschema(schema="http://json-schema.org/draft-07/schema#")
	@jsonschema(id="https://json.schemastore.org/github-workflow.json")
	close({
		// The name of your workflow. GitHub displays the names of your
		// workflows on your repository's actions page. If you omit this
		// field, GitHub sets the name to the workflow's filename.
		name?: string

		// The name of the GitHub event that triggers the workflow. You
		// can provide a single event string, array of events, array of
		// event types, or an event configuration map that schedules a
		// workflow or restricts the execution of a workflow to specific
		// files, tags, or branch changes. For a list of available
		// events, see
		// https://help.github.com/en/github/automating-your-workflow-with-github-actions/events-that-trigger-workflows.
		on!: matchN(1, [#event, [...#event] & [_, ...], close({
			branch_protection_rule?:      #eventObject
			check_run?:                   #eventObject
			check_suite?:                 #eventObject
			create?:                      #eventObject
			delete?:                      #eventObject
			deployment?:                  #eventObject
			deployment_status?:           #eventObject
			discussion?:                  #eventObject
			discussion_comment?:          #eventObject
			fork?:                        #eventObject
			gollum?:                      #eventObject
			issue_comment?:               #eventObject
			issues?:                      #eventObject
			label?:                       #eventObject
			merge_group?:                 #eventObject
			milestone?:                   #eventObject
			page_build?:                  #eventObject
			project?:                     #eventObject
			project_card?:                #eventObject
			project_column?:              #eventObject
			public?:                      #eventObject
			pull_request?:                #ref
			pull_request_review?:         #eventObject
			pull_request_review_comment?: #eventObject
			pull_request_target?:         #ref
			push?:                        #ref
			registry_package?:            #eventObject
			release?:                     #eventObject
			status?:                      #eventObject
			watch?:                       #eventObject

			// Allows workflows to be reused by other workflows.
			workflow_call?: null | bool | number | string | [...] | {
				// When using the workflow_call keyword, you can optionally
				// specify inputs that are passed to the called workflow from the
				// caller workflow.
				inputs?: close({
					{[=~"^[_a-zA-Z][a-zA-Z0-9_-]*$"]: close({
						// A string description of the input parameter.
						description?: string

						// A boolean to indicate whether the action requires the input
						// parameter. Set to true when the parameter is required.
						required?: bool

						// Required if input is defined for the on.workflow_call keyword.
						// The value of this parameter is a string specifying the data
						// type of the input. This must be one of: boolean, number, or
						// string.
						type!: "boolean" | "number" | "string"

						// The default value is used when an input parameter isn't
						// specified in a workflow file.
						default?: bool | number | string
					})
					}
				})

				// When using the workflow_call keyword, you can optionally
				// specify inputs that are passed to the called workflow from the
				// caller workflow.
				outputs?: close({
					{[=~"^[_a-zA-Z][a-zA-Z0-9_-]*$"]: close({
						// A string description of the output parameter.
						description?: string

						// The value that the output parameter will be mapped to. You can
						// set this to a string or an expression with context. For
						// example, you can use the steps context to set the value of an
						// output to the output value of a step.
						value!: string
					})
					}
				})

				// A map of the secrets that can be used in the called workflow.
				// Within the called workflow, you can use the secrets context to
				// refer to a secret.
				secrets?: null | bool | number | string | [...] | close({
					{[=~"^[_a-zA-Z][a-zA-Z0-9_-]*$"]: null | bool | number | string | [...] | close({
						// A string description of the secret parameter.
						description?: string

						// A boolean specifying whether the secret must be supplied.
						required?: bool
					})
					}
				})
				...
			}

			// You can now create workflows that are manually triggered with
			// the new workflow_dispatch event. You will then see a 'Run
			// workflow' button on the Actions tab, enabling you to easily
			// trigger a run.
			workflow_dispatch?: null | bool | number | string | [...] | close({
				// Input parameters allow you to specify data that the action
				// expects to use during runtime. GitHub stores input parameters
				// as environment variables. Input ids with uppercase letters are
				// converted to lowercase during runtime. We recommended using
				// lowercase input ids.
				inputs?: close({
					{[=~"^[_a-zA-Z][a-zA-Z0-9_-]*$"]: #workflowDispatchInput}
				})
			})
			workflow_run?:        #eventObject
			repository_dispatch?: #eventObject

			// You can schedule a workflow to run at specific UTC times using
			// POSIX cron syntax
			// (https://pubs.opengroup.org/onlinepubs/9699919799/utilities/crontab.html#tag_20_25_07).
			// Scheduled workflows run on the latest commit on the default or
			// base branch. The shortest interval you can run scheduled
			// workflows is once every 5 minutes.
			// Note: GitHub Actions does not support the non-standard syntax
			// @yearly, @monthly, @weekly, @daily, @hourly, and @reboot.
			// You can use crontab guru (https://crontab.guru/). to help
			// generate your cron syntax and confirm what time it will run.
			// To help you get started, there is also a list of crontab guru
			// examples (https://crontab.guru/examples.html).
			schedule?: [...close({
				cron?: string
			})] & [_, ...]
		})])
		env?:      #env
		defaults?: #defaults

		// Concurrency ensures that only a single job or workflow using
		// the same concurrency group will run at a time. A concurrency
		// group can be any string or expression. The expression can use
		// any context except for the secrets context.
		// You can also specify concurrency at the workflow level.
		// When a concurrent job or workflow is queued, if another job or
		// workflow using the same concurrency group in the repository is
		// in progress, the queued job or workflow will be pending. Any
		// previously pending job or workflow in the concurrency group
		// will be canceled. To also cancel any currently running job or
		// workflow in the same concurrency group, specify
		// cancel-in-progress: true.
		concurrency?: matchN(1, [string, #concurrency])

		// A workflow run is made up of one or more jobs. Jobs run in
		// parallel by default. To run jobs sequentially, you can define
		// dependencies on other jobs using the jobs.<job_id>.needs
		// keyword.
		// Each job runs in a fresh instance of the virtual environment
		// specified by runs-on.
		// You can run an unlimited number of jobs as long as you are
		// within the workflow usage limits. For more information, see
		// https://help.github.com/en/github/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#usage-limits.
		jobs!: struct.MinFields(1) & close({
			{[=~"^[_a-zA-Z][a-zA-Z0-9_-]*$"]: matchN(1, [#normalJob, #reusableWorkflowCallJob])}
		})

		// The name for workflow runs generated from the workflow. GitHub
		// displays the workflow run name in the list of workflow runs on
		// your repository's 'Actions' tab.
		"run-name"?:  string
		permissions?: #permissions
	})

	#: "permissions-event": close({
		actions?:               #."permissions-level"
		attestations?:          #."permissions-level"
		checks?:                #."permissions-level"
		contents?:              #."permissions-level"
		deployments?:           #."permissions-level"
		discussions?:           #."permissions-level"
		"id-token"?:            #."permissions-level"
		issues?:                #."permissions-level"
		models?:                "read" | "none"
		packages?:              #."permissions-level"
		pages?:                 #."permissions-level"
		"pull-requests"?:       #."permissions-level"
		"repository-projects"?: #."permissions-level"
		"security-events"?:     #."permissions-level"
		statuses?:              #."permissions-level"
	})

	#: "permissions-level": "read" | "write" | "none"

	// Using the working-directory keyword, you can specify the
	// working directory of where to run the command.
	#: "working-directory": string

	#architecture: "ARM32" | "x64" | "x86"

	#branch: #globs

	#concurrency: close({
		// When a concurrent job or workflow is queued, if another job or
		// workflow using the same concurrency group in the repository is
		// in progress, the queued job or workflow will be pending. Any
		// previously pending job or workflow in the concurrency group
		// will be canceled.
		group!: string

		// To cancel any currently running job or workflow in the same
		// concurrency group, specify cancel-in-progress: true.
		"cancel-in-progress"?: matchN(1, [bool, #expressionSyntax])
	})

	#configuration: matchN(1, [string, number, bool, {
		[string]: #configuration
	}, [...#configuration]])

	#container: close({
		// The Docker image to use as the container to run the action. The
		// value can be the Docker Hub image name or a registry name.
		image!: string

		// If the image's container registry requires authentication to
		// pull the image, you can use credentials to set a map of the
		// username and password. The credentials are the same values
		// that you would provide to the `docker login` command.
		credentials?: {
			username?: string
			password?: string
			...
		}
		env?: #env

		// Sets an array of ports to expose on the container.
		ports?: [...number | string] & [_, ...]

		// Sets an array of volumes for the container to use. You can use
		// volumes to share data between services or other steps in a
		// job. You can specify named Docker volumes, anonymous Docker
		// volumes, or bind mounts on the host.
		// To specify a volume, you specify the source and destination
		// path: <source>:<destinationPath>
		// The <source> is a volume name or an absolute path on the host
		// machine, and <destinationPath> is an absolute path in the
		// container.
		volumes?: [...string] & [_, ...]

		// Additional Docker container resource options. For a list of
		// options, see
		// https://docs.docker.com/engine/reference/commandline/create/#options.
		options?: string
	})

	#defaults: struct.MinFields(1) & close({
		run?: struct.MinFields(1) & close({
			shell?:               #shell
			"working-directory"?: #."working-directory"
		})
	})

	// To set custom environment variables, you need to specify the
	// variables in the workflow file. You can define environment
	// variables for a step, job, or entire workflow using the
	// jobs.<job_id>.steps[*].env, jobs.<job_id>.env, and env
	// keywords. For more information, see
	// https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepsenv
	#env: matchN(1, [{
		[string]: bool | number | string
	}, #stringContainingExpressionSyntax])

	// The environment that the job references
	#environment: close({
		// The name of the environment configured in the repo.
		name!: string

		// A deployment URL
		url?: string
	})

	#event: "branch_protection_rule" | "check_run" | "check_suite" | "create" | "delete" | "deployment" | "deployment_status" | "discussion" | "discussion_comment" | "fork" | "gollum" | "issue_comment" | "issues" | "label" | "merge_group" | "milestone" | "page_build" | "project" | "project_card" | "project_column" | "public" | "pull_request" | "pull_request_review" | "pull_request_review_comment" | "pull_request_target" | "push" | "registry_package" | "release" | "status" | "watch" | "workflow_call" | "workflow_dispatch" | "workflow_run" | "repository_dispatch"

	#eventObject: null | {
		...
	}

	#expressionSyntax: =~"""
		^\\$\\{\\{(.|[\r
		])*\\}\\}$
		"""

	#globs: [...strings.MinRunes(1)] & [_, ...]

	// Identifies any jobs that must complete successfully before this
	// job will run. It can be a string or array of strings. If a job
	// fails, all jobs that need it are skipped unless the jobs use a
	// conditional statement that causes the job to continue.
	#jobNeeds: matchN(1, [[...#name] & [_, ...], #name])

	#machine: "linux" | "macos" | "windows"

	// A build matrix is a set of different configurations of the
	// virtual environment. For example you might run a job against
	// more than one supported version of a language, operating
	// system, or tool. Each configuration is a copy of the job that
	// runs and reports a status.
	// You can specify a matrix by supplying an array for the
	// configuration options. For example, if the GitHub virtual
	// environment supports Node.js versions 6, 8, and 10 you could
	// specify an array of those versions in the matrix.
	// When you define a matrix of operating systems, you must set the
	// required runs-on keyword to the operating system of the
	// current job, rather than hard-coding the operating system
	// name. To access the operating system name, you can use the
	// matrix.os context parameter to set runs-on. For more
	// information, see
	// https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions.
	#matrix: matchN(1, [struct.MinFields(1) & {
		{[=~"^(in|ex)clude$"]: matchN(1, [#expressionSyntax, [...{
			[string]: #configuration
		}] & [_, ...]])
		}
		{[!~"^(in|ex)clude$" & !~"^()$"]: matchN(1, [[...#configuration] & [_, ...], #expressionSyntax])}
	}, #expressionSyntax])

	#name: =~"^[_a-zA-Z][a-zA-Z0-9_-]*$"

	// Each job must have an id to associate with the job. The key
	// job_id is a string and its value is a map of the job's
	// configuration data. You must replace <job_id> with a string
	// that is unique to the jobs object. The <job_id> must start
	// with a letter or _ and contain only alphanumeric characters,
	// -, or _.
	#normalJob: close({
		// The name of the job displayed on GitHub.
		name?:        string
		needs?:       #jobNeeds
		permissions?: #permissions

		// The type of machine to run the job on. The machine can be
		// either a GitHub-hosted runner, or a self-hosted runner.
		"runs-on"!: matchN(>=1, [string, [string, ...string] & [_, ...] & [...], {
			group?: string
			labels?: matchN(1, [string, [...string]])
			...
		}, #stringContainingExpressionSyntax, #expressionSyntax])

		// The environment that the job references.
		environment?: matchN(1, [string, #environment])

		// A map of outputs for a job. Job outputs are available to all
		// downstream jobs that depend on this job.
		outputs?: struct.MinFields(1) & {
			[string]: string
		}
		env?:      #env
		defaults?: #defaults

		// You can use the if conditional to prevent a job from running
		// unless a condition is met. You can use any supported context
		// and expression to create a conditional.
		// Expressions in an if conditional do not require the ${{ }}
		// syntax. For more information, see
		// https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions.
		if?: bool | number | string

		// A job contains a sequence of tasks called steps. Steps can run
		// commands, run setup tasks, or run an action in your
		// repository, a public repository, or an action published in a
		// Docker registry. Not all steps run actions, but all actions
		// run as a step. Each step runs in its own process in the
		// virtual environment and has access to the workspace and
		// filesystem. Because steps run in their own process, changes to
		// environment variables are not preserved between steps. GitHub
		// provides built-in steps to set up and complete a job.
		// Must contain either `uses` or `run`
		steps?: [...#step] & [_, ...]

		// The maximum number of minutes to let a workflow run before
		// GitHub automatically cancels it. Default: 360
		"timeout-minutes"?: matchN(1, [number, #expressionSyntax])

		// A strategy creates a build matrix for your jobs. You can define
		// different variations of an environment to run each job in.
		strategy?: close({
			matrix!: #matrix

			// When set to true, GitHub cancels all in-progress jobs if any
			// matrix job fails. Default: true
			"fail-fast"?: bool | string

			// The maximum number of jobs that can run simultaneously when
			// using a matrix job strategy. By default, GitHub will maximize
			// the number of jobs run in parallel depending on the available
			// runners on GitHub-hosted virtual machines.
			"max-parallel"?: number | string
		})

		// Prevents a workflow run from failing when a job fails. Set to
		// true to allow a workflow run to pass when this job fails.
		"continue-on-error"?: matchN(1, [bool, #expressionSyntax])

		// A container to run any steps in a job that don't already
		// specify a container. If you have steps that use both script
		// and container actions, the container actions will run as
		// sibling containers on the same network with the same volume
		// mounts.
		// If you do not set a container, all steps will run directly on
		// the host specified by runs-on unless a step refers to an
		// action configured to run in a container.
		container?: matchN(1, [string, #container])

		// Additional containers to host services for a job in a workflow.
		// These are useful for creating databases or cache services like
		// redis. The runner on the virtual machine will automatically
		// create a network and manage the life cycle of the service
		// containers.
		// When you use a service container for a job or your step uses
		// container actions, you don't need to set port information to
		// access the service. Docker automatically exposes all ports
		// between containers on the same network.
		// When both the job and the action run in a container, you can
		// directly reference the container by its hostname. The hostname
		// is automatically mapped to the service name.
		// When a step does not use a container action, you must access
		// the service using localhost and bind the ports.
		services?: [string]: #container

		// Concurrency ensures that only a single job or workflow using
		// the same concurrency group will run at a time. A concurrency
		// group can be any string or expression. The expression can use
		// any context except for the secrets context.
		// You can also specify concurrency at the workflow level.
		// When a concurrent job or workflow is queued, if another job or
		// workflow using the same concurrency group in the repository is
		// in progress, the queued job or workflow will be pending. Any
		// previously pending job or workflow in the concurrency group
		// will be canceled. To also cancel any currently running job or
		// workflow in the same concurrency group, specify
		// cancel-in-progress: true.
		concurrency?: matchN(1, [string, #concurrency])
	})

	#path: #globs

	// You can modify the default permissions granted to the
	// GITHUB_TOKEN, adding or removing access as required, so that
	// you only allow the minimum required access.
	#permissions: matchN(1, ["read-all" | "write-all", #."permissions-event"])

	#ref: matchN(1, [matchN(3, [matchN(0, [null | bool | number | string | [...] | {
		branches!:          _
		"branches-ignore"!: _
		...
	}]) & {
		...
	}, matchN(0, [null | bool | number | string | [...] | {
		tags!:          _
		"tags-ignore"!: _
		...
	}]) & {
		...
	}, matchN(0, [null | bool | number | string | [...] | {
		paths!:          _
		"paths-ignore"!: _
		...
	}]) & {
		...
	}]), null]) & (null | {
		branches?:          #branch
		"branches-ignore"?: #branch
		tags?:              #branch
		"tags-ignore"?:     #branch
		paths?:             #path
		"paths-ignore"?:    #path
		...
	})

	// Each job must have an id to associate with the job. The key
	// job_id is a string and its value is a map of the job's
	// configuration data. You must replace <job_id> with a string
	// that is unique to the jobs object. The <job_id> must start
	// with a letter or _ and contain only alphanumeric characters,
	// -, or _.
	#reusableWorkflowCallJob: close({
		// The name of the job displayed on GitHub.
		name?:        string
		needs?:       #jobNeeds
		permissions?: #permissions

		// You can use the if conditional to prevent a job from running
		// unless a condition is met. You can use any supported context
		// and expression to create a conditional.
		// Expressions in an if conditional do not require the ${{ }}
		// syntax. For more information, see
		// https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions.
		if?: bool | number | string

		// The location and version of a reusable workflow file to run as
		// a job, of the form './{path/to}/{localfile}.yml' or
		// '{owner}/{repo}/{path}/{filename}@{ref}'. {ref} can be a SHA,
		// a release tag, or a branch name. Using the commit SHA is the
		// safest for stability and security.
		uses!: =~"^(.+\\/)+(.+)\\.(ya?ml)(@.+)?$"
		with?: #env

		// When a job is used to call a reusable workflow, you can use
		// 'secrets' to provide a map of secrets that are passed to the
		// called workflow. Any secrets that you pass must match the
		// names defined in the called workflow.
		secrets?: matchN(1, [#env, "inherit"])

		// A strategy creates a build matrix for your jobs. You can define
		// different variations of an environment to run each job in.
		strategy?: close({
			matrix!: #matrix

			// When set to true, GitHub cancels all in-progress jobs if any
			// matrix job fails. Default: true
			"fail-fast"?: bool | string

			// The maximum number of jobs that can run simultaneously when
			// using a matrix job strategy. By default, GitHub will maximize
			// the number of jobs run in parallel depending on the available
			// runners on GitHub-hosted virtual machines.
			"max-parallel"?: number | string
		})

		// Concurrency ensures that only a single job or workflow using
		// the same concurrency group will run at a time. A concurrency
		// group can be any string or expression. The expression can use
		// any context except for the secrets context.
		// You can also specify concurrency at the workflow level.
		// When a concurrent job or workflow is queued, if another job or
		// workflow using the same concurrency group in the repository is
		// in progress, the queued job or workflow will be pending. Any
		// previously pending job or workflow in the concurrency group
		// will be canceled. To also cancel any currently running job or
		// workflow in the same concurrency group, specify
		// cancel-in-progress: true.
		concurrency?: matchN(1, [string, #concurrency])
	})

	// You can override the default shell settings in the runner's
	// operating system using the shell keyword. You can use built-in
	// shell keywords, or you can define a custom set of shell
	// options.
	#shell: matchN(>=1, [string, "bash" | "pwsh" | "python" | "sh" | "cmd" | "powershell"])

	#step: matchN(1, [{
		uses!: _
		...
	}, {
		run!: _
		...
	}]) & close({
		_t0="working-directory"?: _
		if _t0 != _|_ {
			run!: _
		}
		shell?: _
		if shell != _|_ {
			run!: _
		}
		{}

		// A unique identifier for the step. You can use the id to
		// reference the step in contexts. For more information, see
		// https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions.
		id?: string

		// You can use the if conditional to prevent a step from running
		// unless a condition is met. You can use any supported context
		// and expression to create a conditional.
		// Expressions in an if conditional do not require the ${{ }}
		// syntax. For more information, see
		// https://help.github.com/en/articles/contexts-and-expression-syntax-for-github-actions.
		if?: bool | number | string

		// A name for your step to display on GitHub.
		name?: string

		// Selects an action to run as part of a step in your job. An
		// action is a reusable unit of code. You can use an action
		// defined in the same repository as the workflow, a public
		// repository, or in a published Docker container image
		// (https://hub.docker.com/).
		// We strongly recommend that you include the version of the
		// action you are using by specifying a Git ref, SHA, or Docker
		// tag number. If you don't specify a version, it could break
		// your workflows or cause unexpected behavior when the action
		// owner publishes an update.
		// - Using the commit SHA of a released action version is the
		// safest for stability and security.
		// - Using the specific major action version allows you to receive
		// critical fixes and security patches while still maintaining
		// compatibility. It also assures that your workflow should still
		// work.
		// - Using the master branch of an action may be convenient, but
		// if someone releases a new major version with a breaking
		// change, your workflow could break.
		// Some actions require inputs that you must set using the with
		// keyword. Review the action's README file to determine the
		// inputs required.
		// Actions are either JavaScript files or Docker containers. If
		// the action you're using is a Docker container you must run the
		// job in a Linux virtual environment. For more details, see
		// https://help.github.com/en/articles/virtual-environments-for-github-actions.
		uses?: string

		// Runs command-line programs using the operating system's shell.
		// If you do not provide a name, the step name will default to
		// the text specified in the run command.
		// Commands run using non-login shells by default. You can choose
		// a different shell and customize the shell used to run
		// commands. For more information, see
		// https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#using-a-specific-shell.
		// Each run keyword represents a new process and shell in the
		// virtual environment. When you provide multi-line commands,
		// each line runs in the same shell.
		run?:                 string
		"working-directory"?: #."working-directory"
		"shell"?:             #shell
		with?:                #env
		env?:                 #env

		// Prevents a job from failing when a step fails. Set to true to
		// allow a job to pass when this step fails.
		"continue-on-error"?: matchN(1, [bool, #expressionSyntax])

		// The maximum number of minutes to run the step before killing
		// the process.
		"timeout-minutes"?: matchN(1, [number, #expressionSyntax])
	})

	#stringContainingExpressionSyntax: =~"""
		^.*\\$\\{\\{(.|[\r
		])*\\}\\}.*$
		"""

	// Selects the types of activity that will trigger a workflow run.
	// Most GitHub events are triggered by more than one type of
	// activity. For example, the event for the release resource is
	// triggered when a release is published, unpublished, created,
	// edited, deleted, or prereleased. The types keyword enables you
	// to narrow down activity that causes the workflow to run. When
	// only one activity type triggers a webhook event, the types
	// keyword is unnecessary.
	// You can use an array of event types. For more information about
	// each event and their activity types, see
	// https://help.github.com/en/articles/events-that-trigger-workflows#webhook-events.
	#types: matchN(1, [[_, ...], string])

	// A string identifier to associate with the input. The value of
	// <input_id> is a map of the input's metadata. The <input_id>
	// must be a unique identifier within the inputs object. The
	// <input_id> must start with a letter or _ and contain only
	// alphanumeric characters, -, or _.
	#workflowDispatchInput: matchN(5, [matchIf({
		type!: "string"
		...
	}, {
		default?: string
		...
	}, _) & {
		...
	}, matchIf({
		type!: "boolean"
		...
	}, {
		default?: bool
		...
	}, _) & {
		...
	}, matchIf({
		type!: "number"
		...
	}, {
		default?: number
		...
	}, _) & {
		...
	}, matchIf({
		type!: "environment"
		...
	}, {
		default?: string
		...
	}, _) & {
		...
	}, matchIf({
		type!: "choice"
		...
	}, {
		options!: _
		...
	}, _) & {
		...
	}]) & close({
		// A string description of the input parameter.
		description!: string

		// A string shown to users using the deprecated input.
		deprecationMessage?: string

		// A boolean to indicate whether the action requires the input
		// parameter. Set to true when the parameter is required.
		required?: bool

		// A string representing the default value. The default value is
		// used when an input parameter isn't specified in a workflow
		// file.
		default?: _

		// A string representing the type of the input.
		type?: "string" | "choice" | "boolean" | "number" | "environment"

		// The options of the dropdown list, if the type is a choice.
		options?: [...string] & [_, ...]
	})
}
