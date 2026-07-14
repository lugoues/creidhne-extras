package creidhne_extras

#BorgmaticConfig:

	close({
		// Constants to use in the configuration file. Within option
		// values,
		// all occurrences of the constant name in curly braces will be
		// replaced with the constant value. For example, if you have a
		// constant named "app_name" with the value "myapp", then the
		// string
		// "{app_name}" will be replaced with "myapp" in the configuration
		// file.
		constants?: {
			...
		}

		// List of source directories and files to back up. Globs and
		// tildes
		// are expanded. Do not backslash spaces in path names. Be aware
		// that
		// by default, Borg treats missing source directories as warnings
		// rather than errors. If you'd like to change that behavior, see
		// https://torsion.org/borgmatic/how-to/customize-warnings-and-errors/
		// or the "source_directories_must_exist" option.
		source_directories?: [...string]

		// If true, then source directories (and root pattern paths) must
		// exist. If they don't, an error is raised. Defaults to false.
		source_directories_must_exist?: bool

		// A required list of local or remote repositories with paths and
		// optional labels (which can be used with the --repository flag
		// to
		// select a repository). Tildes are expanded. Multiple
		// repositories are
		// backed up to in sequence. Borg placeholders can be used. See
		// the
		// output of "borg help placeholders" for details. See ssh_command
		// for
		// SSH options like identity file or port. If systemd service is
		// used,
		// then add local repository paths in the systemd service file to
		// the
		// ReadWritePaths list.
		repositories?: [...close({
			// The local path or Borg URL of the repository.
			path!: string

			// An optional label for the repository, used in logging
			// and to make selecting the repository easier on the
			// command-line.
			label?: string

			// The encryption mode with which to create the repository,
			// only used for the repo-create action. To see the
			// available encryption modes, run "borg init --help" with
			// Borg 1 or "borg repo-create --help" with Borg 2.
			encryption?: string

			// Whether the repository should be created append-only,
			// only used for the repo-create action. Defaults to false.
			append_only?: bool

			// The storage quota with which to create the repository,
			// only used for the repo-create action. Defaults to no
			// quota.
			storage_quota?: string

			// Whether any missing parent directories of the repository
			// path should be created, only used for the repo-create
			// action. Defaults to false. (This option is supported
			// for Borg 1.x only.)
			make_parent_directories?: bool
		})]

		// Working directory to use when running actions, useful for
		// backing up
		// using relative source directory paths. Does not currently apply
		// to
		// borgmatic configuration file paths or includes. Tildes are
		// expanded.
		// See
		// http://borgbackup.readthedocs.io/en/stable/usage/create.html
		// for
		// details. Defaults to not set.
		working_directory?: string

		// Stay in same file system; do not cross mount points beyond the
		// given
		// source directories. Defaults to false.
		one_file_system?: bool

		// Only store/extract numeric user and group identifiers. Defaults
		// to
		// false.
		numeric_ids?: bool

		// Store atime into archive. Defaults to true in Borg < 1.2, false
		// in
		// Borg 1.2+.
		atime?: bool

		// Store ctime into archive. Defaults to true.
		ctime?: bool

		// Store birthtime (creation date) into archive. Defaults to true.
		birthtime?: bool

		// Use Borg's --read-special flag to allow backup of block and
		// other
		// special devices. Use with caution, as it will lead to problems
		// if
		// used when backing up special devices such as /dev/zero.
		// Defaults to
		// false. But when a database hook is used, the setting here is
		// ignored
		// and read_special is considered true.
		read_special?: bool

		// Record filesystem flags (e.g. NODUMP, IMMUTABLE) in archive.
		// Defaults to true.
		flags?: bool

		// Mode in which to operate the files cache. See
		// http://borgbackup.readthedocs.io/en/stable/usage/create.html
		// for
		// details. Defaults to "ctime,size,inode".
		files_cache?: string

		// Alternate Borg local executable. Defaults to "borg".
		local_path?: string

		// Alternate Borg remote executable. Defaults to "borg".
		remote_path?: string

		// Any paths matching these patterns are included/excluded from
		// backups. Recursion root patterns ("R ...") are effectively the
		// same
		// as "source_directories"; they tell Borg which paths to backup
		// (modulo any excludes). Globs are expanded. (Tildes are not.)
		// See
		// the output of "borg help patterns" for more details. Quote any
		// value
		// if it contains leading punctuation, so it parses correctly.
		patterns?: [...string]

		// Read include/exclude patterns from one or more separate named
		// files,
		// one pattern per line. See the output of "borg help patterns"
		// for
		// more details.
		patterns_from?: [...string]

		// Any paths matching these patterns are excluded from backups.
		// Globs
		// and tildes are expanded. Note that a glob pattern must either
		// start
		// with a glob or be an absolute path. Do not backslash spaces in
		// path
		// names. See the output of "borg help patterns" for more details.
		exclude_patterns?: [...string]

		// Read exclude patterns from one or more separate named files,
		// one
		// pattern per line. See the output of "borg help patterns" for
		// more
		// details.
		exclude_from?: [...string]

		// Exclude directories that contain a CACHEDIR.TAG file. See
		// http://www.brynosaurus.com/cachedir/spec.html for details.
		// Defaults
		// to false.
		exclude_caches?: bool

		// Exclude directories that contain a file with the given
		// filenames.
		// Defaults to not set.
		exclude_if_present?: [...string]

		// If true, the exclude_if_present filename is included in
		// backups.
		// Defaults to false, meaning that the exclude_if_present filename
		// is
		// omitted from backups.
		keep_exclude_tags?: bool

		// Exclude files with the NODUMP flag. Defaults to false. (This
		// option
		// is supported for Borg 1.x only.)
		exclude_nodump?: bool

		// Deprecated. Only used for locating database dumps and bootstrap
		// metadata within backup archives created prior to deprecation.
		// Replaced by user_runtime_directory and user_state_directory.
		// Defaults to ~/.borgmatic
		borgmatic_source_directory?: string

		// Path for storing temporary runtime data like streaming database
		// dumps and bootstrap metadata. borgmatic automatically creates
		// and
		// uses a "borgmatic" subdirectory here. Defaults to
		// $XDG_RUNTIME_DIR
		// or or $TMPDIR or $TEMP or /run/user/$UID.
		user_runtime_directory?: string

		// Path for storing borgmatic state files like records of when
		// checks
		// last ran. borgmatic automatically creates and uses a
		// "borgmatic"
		// subdirectory here. If you change this option, borgmatic must
		// create the check records again (and therefore re-run checks).
		// Defaults to $XDG_STATE_HOME or ~/.local/state.
		user_state_directory?: string

		// The standard output of this command is used to unlock the
		// encryption
		// key. Only use on repositories that were initialized with
		// passcommand/repokey/keyfile encryption. Note that if both
		// encryption_passcommand and encryption_passphrase are set, then
		// encryption_passphrase takes precedence. This can also be used
		// to
		// access encrypted systemd service credentials. Defaults to not
		// set.
		// For more details, see:
		// https://torsion.org/borgmatic/how-to/provide-your-passwords/
		encryption_passcommand?: string

		// Passphrase to unlock the encryption key with. Only use on
		// repositories that were initialized with
		// passphrase/repokey/keyfile
		// encryption. Quote the value if it contains punctuation, so it
		// parses
		// correctly. And backslash any quote or backslash literals as
		// well.
		// Defaults to not set. Supports the "{credential ...}" syntax.
		encryption_passphrase?: string

		// Number of seconds between each checkpoint during a long-running
		// backup. See
		// https://borgbackup.readthedocs.io/en/stable/faq.html for
		// details. Defaults to checkpoints every 1800 seconds (30
		// minutes).
		checkpoint_interval?: int

		// Number of backed up bytes between each checkpoint during a
		// long-running backup. Only supported with Borg 2+. See
		// https://borgbackup.readthedocs.io/en/stable/faq.html for
		// details.
		// Defaults to only time-based checkpointing (see
		// "checkpoint_interval") instead of volume-based checkpointing.
		checkpoint_volume?: int

		// Specify the parameters passed to the chunker (CHUNK_MIN_EXP,
		// CHUNK_MAX_EXP, HASH_MASK_BITS, HASH_WINDOW_SIZE). See
		// https://borgbackup.readthedocs.io/en/stable/internals.html for
		// details. Defaults to "19,23,21,4095".
		chunker_params?: string

		// Type of compression to use when creating archives. (Compression
		// level can be added separated with a comma, like "zstd,7".) See
		// http://borgbackup.readthedocs.io/en/stable/usage/create.html
		// for
		// details. Defaults to "lz4".
		compression?: string

		// Mode for recompressing data chunks according to MODE.
		// Possible modes are:
		// * "if-different": Recompress if the current compression
		// is with a different compression algorithm.
		// * "always": Recompress even if the current compression
		// is with the same compression algorithm. Use this to change
		// the compression level.
		// * "never": Do not recompress. Use this option to explicitly
		// prevent recompression.
		// See
		// https://borgbackup.readthedocs.io/en/stable/usage/recreate.html
		// for details. Defaults to "never".
		recompress?: "if-different" | "always" | "never"

		// Remote network upload rate limit in kiBytes/second. Defaults to
		// unlimited.
		upload_rate_limit?: int

		// Size of network upload buffer in MiB. Defaults to no buffer.
		upload_buffer_size?: int

		// Number of times to retry a failing backup before giving up.
		// Defaults
		// to 0 (i.e., does not attempt retry).
		retries?: int

		// Wait time between retries (in seconds) to allow transient
		// issues
		// to pass. Increases after each retry by that same wait time as a
		// form of backoff. Defaults to 0 (no wait).
		retry_wait?: int

		// Directory where temporary Borg files are stored. Defaults to
		// $TMPDIR. See "Resource Usage" at
		// https://borgbackup.readthedocs.io/en/stable/usage/general.html
		// for
		// details.
		temporary_directory?: string

		// Command to use instead of "ssh". This can be used to specify
		// ssh
		// options. Defaults to not set.
		ssh_command?: string

		// Base path used for various Borg directories. Defaults to $HOME,
		// ~$USER, or ~.
		borg_base_directory?: string

		// Path for Borg configuration files. Defaults to
		// $borg_base_directory/.config/borg
		borg_config_directory?: string

		// Path for Borg cache files. Defaults to
		// $borg_base_directory/.cache/borg
		borg_cache_directory?: string

		// Enables or disables the use of chunks.archive.d for faster
		// cache
		// resyncs in Borg. If true, value is set to "yes" (default) else
		// it's set to "no", reducing disk usage but slowing resyncs.
		use_chunks_archive?: bool

		// Maximum time to live (ttl) for entries in the Borg files cache.
		borg_files_cache_ttl?: int

		// Path for Borg security and encryption nonce files. Defaults to
		// $borg_config_directory/security
		borg_security_directory?: string

		// Path for Borg encryption key files. Defaults to
		// $borg_config_directory/keys
		borg_keys_directory?: string

		// Path for the Borg repository key file, for use with a
		// repository
		// created with "keyfile" encryption.
		borg_key_file?: string

		// A list of Borg exit codes that should be elevated to errors or
		// squashed to warnings as indicated. By default, Borg error exit
		// codes
		// (2 to 99) are treated as errors while warning exit codes (1 and
		// 100+) are treated as warnings. Exit codes other than 1 and 2
		// are
		// only present in Borg 1.4.0+.
		borg_exit_codes?: [...close({
			// The exit code for an existing Borg warning or error.
			code!: matchN(0, [0]) & int

			// Whether to consider the exit code as an error or as a
			// warning in borgmatic.
			treat_as!: "error" | "warning"
		})]

		// Umask used for when executing Borg or calling hooks. Defaults
		// to
		// 0077 for Borg or the umask that borgmatic is run with for
		// hooks.
		umask?: int

		// Maximum seconds to wait for acquiring a repository/cache lock.
		// Defaults to 1.
		lock_wait?: int

		// Name of the archive to create. Borg placeholders can be used.
		// See
		// the output of "borg help placeholders" for details. Defaults to
		// "{hostname}-{now:%Y-%m-%dT%H:%M:%S.%f}" with Borg 1 and
		// "{hostname}" with Borg 2, as Borg 2 does not require unique
		// archive names; identical archive names form a common "series"
		// that
		// can be targeted together. When running actions like repo-list,
		// info, or check, borgmatic automatically tries to match only
		// archives created with this name format.
		archive_name_format?: string

		// A Borg pattern for filtering down the archives used by
		// borgmatic
		// actions that operate on multiple archives. For Borg 1.x, use a
		// shell
		// pattern here and see the output of "borg help placeholders" for
		// details. For Borg 2.x, see the output of "borg help
		// match-archives".
		// If match_archives is not specified, borgmatic defaults to
		// deriving
		// the match_archives value from archive_name_format.
		match_archives?: string

		// Bypass Borg error about a repository that has been moved.
		// Defaults
		// to false.
		relocated_repo_access_is_ok?: bool

		// Bypass Borg error about a previously unknown unencrypted
		// repository.
		// Defaults to false.
		unknown_unencrypted_repo_access_is_ok?: bool

		// When set true, display debugging information that includes
		// passphrases used and passphrase related environment variables
		// set.
		// Defaults to false.
		debug_passphrase?: bool

		// When set true, always shows passphrase and its hex UTF-8 byte
		// sequence. Defaults to false.
		display_passphrase?: bool

		// Bypass Borg confirmation about check with repair option.
		// Defaults to
		// false and an interactive prompt from Borg.
		check_i_know_what_i_am_doing?: bool

		// Additional options to pass directly to particular Borg
		// commands,
		// handy for Borg options that borgmatic does not yet support
		// natively.
		// Note that borgmatic does not perform any validation on these
		// options. Running borgmatic with "--verbosity 2" shows the exact
		// Borg
		// command-line invocation.
		extra_borg_options?: close({
			// Extra command-line options to pass to "borg break-lock".
			break_lock?: string

			// Extra command-line options to pass to "borg check".
			check?: string

			// Extra command-line options to pass to "borg compact".
			compact?: string

			// Extra command-line options to pass to "borg create".
			create?: string

			// Extra command-line options to pass to "borg delete".
			delete?: string

			// Extra command-line options to pass to "borg export-tar".
			export_tar?: string

			// Extra command-line options to pass to "borg extract".
			extract?: string

			// Extra command-line options to pass to "borg key export".
			key_export?: string

			// Extra command-line options to pass to "borg key import".
			key_import?: string

			// Extra command-line options to pass to "borg key
			// change-passphrase".
			key_change_passphrase?: string

			// Extra command-line options to pass to "borg info".
			info?: string

			// Deprecated. Use "repo_create" instead. Extra command-line
			// options to pass to "borg init" / "borg repo-create".
			init?: string

			// Extra command-line options to pass to "borg list".
			list?: string

			// Extra command-line options to pass to "borg mount".
			mount?: string

			// Extra command-line options to pass to "borg prune".
			prune?: string

			// Extra command-line options to pass to "borg recreate".
			recreate?: string

			// Extra command-line options to pass to "borg rename".
			rename?: string

			// Extra command-line options to pass to "borg init" / "borg
			// repo-create".
			repo_create?: string

			// Extra command-line options to pass to "borg repo-delete".
			repo_delete?: string

			// Extra command-line options to pass to "borg repo-info".
			repo_info?: string

			// Extra command-line options to pass to "borg repo-list".
			repo_list?: string

			// Extra command-line options to pass to "borg transfer".
			transfer?: string

			// Extra command-line options to pass to "borg umount".
			umount?: string
		})

		// Keep all archives within this time interval. See "skip_actions"
		// for
		// disabling pruning altogether.
		keep_within?: string

		// Number of secondly archives to keep.
		keep_secondly?: int

		// Number of minutely archives to keep.
		keep_minutely?: int

		// Number of hourly archives to keep.
		keep_hourly?: int

		// Number of daily archives to keep.
		keep_daily?: int

		// Number of weekly archives to keep.
		keep_weekly?: int

		// Number of monthly archives to keep.
		keep_monthly?: int

		// Number of yearly archives to keep.
		keep_yearly?: int

		// Number of quarterly archives to keep (13 week strategy).
		keep_13weekly?: int

		// Number of quarterly archives to keep (3 month strategy).
		keep_3monthly?: int

		// Deprecated. When pruning or checking archives, only consider
		// archive
		// names starting with this prefix. Borg placeholders can be used.
		// See
		// the output of "borg help placeholders" for details. If a prefix
		// is
		// not specified, borgmatic defaults to matching archives based on
		// the
		// archive_name_format (see above).
		prefix?: string

		// Minimum saved space percentage threshold for compacting a
		// segment,
		// defaults to 10.
		compact_threshold?: int

		// List of one or more consistency checks to run on a periodic
		// basis
		// (if "frequency" is set) or every time borgmatic runs checks (if
		// "frequency" is omitted).
		checks?: [...matchN(1, [close({
			// Name of the consistency check to run:
			// * "repository" checks the consistency of the
			// repository.
			// * "archives" checks all of the archives.
			// * "data" verifies the integrity of the data
			// within the archives and implies the "archives"
			// check as well.
			// * "spot" checks that some percentage of source
			// files are found in the most recent archive (with
			// identical contents).
			// * "extract" does an extraction dry-run of the
			// most recent archive.
			// * See "skip_actions" for disabling checks
			// altogether.
			name!: "archives" | "data" | "extract" | "disabled"

			// How frequently to run this type of consistency
			// check (as a best effort). The value is a number
			// followed by a unit of time. E.g., "2 weeks" to
			// run this consistency check no more than every
			// two weeks for a given repository or "1 month" to
			// run it no more than monthly. Defaults to
			// "always": running this check every time checks
			// are run.
			frequency?: string

			// After the "frequency" duration has elapsed, only
			// run this check if the current day of the week
			// matches one of these values (the name of a day of
			// the week in the current locale). "weekday" and
			// "weekend" are also accepted. Defaults to running
			// the check on any day of the week.
			only_run_on?: [...string]
		}), close({
			// Name of the consistency check to run:
			// * "repository" checks the consistency of the
			// repository.
			// * "archives" checks all of the archives.
			// * "data" verifies the integrity of the data
			// within the archives and implies the "archives"
			// check as well.
			// * "spot" checks that some percentage of source
			// files are found in the most recent archive (with
			// identical contents).
			// * "extract" does an extraction dry-run of the
			// most recent archive.
			// * See "skip_actions" for disabling checks
			// altogether.
			name!: "repository"

			// How frequently to run this type of consistency
			// check (as a best effort). The value is a number
			// followed by a unit of time. E.g., "2 weeks" to
			// run this consistency check no more than every
			// two weeks for a given repository or "1 month" to
			// run it no more than monthly. Defaults to
			// "always": running this check every time checks
			// are run.
			frequency?: string

			// After the "frequency" duration has elapsed, only
			// run this check if the current day of the week
			// matches one of these values (the name of a day of
			// the week in the current locale). "weekday" and
			// "weekend" are also accepted. Defaults to running
			// the check on any day of the week.
			only_run_on?: [...string]

			// How many seconds to check the repository before
			// interrupting the check. Useful for splitting a
			// long-running repository check into multiple
			// partial checks. Defaults to no interruption. Only
			// applies to the "repository" check, does not check
			// the repository index and is not compatible with
			// the "--repair" flag.
			max_duration?: int
		}), close({
			// Name of the consistency check to run:
			// * "repository" checks the consistency of the
			// repository.
			// * "archives" checks all of the archives.
			// * "data" verifies the integrity of the data
			// within the archives and implies the "archives"
			// check as well.
			// * "spot" checks that some percentage of source
			// files are found in the most recent archive (with
			// identical contents).
			// * "extract" does an extraction dry-run of the
			// most recent archive.
			// * See "skip_actions" for disabling checks
			// altogether.
			name!: "spot"

			// How frequently to run this type of consistency
			// check (as a best effort). The value is a number
			// followed by a unit of time. E.g., "2 weeks" to
			// run this consistency check no more than every
			// two weeks for a given repository or "1 month" to
			// run it no more than monthly. Defaults to
			// "always": running this check every time checks
			// are run.
			frequency?: string

			// After the "frequency" duration has elapsed, only
			// run this check if the current day of the week
			// matches one of these values (the name of a day of
			// the week in the current locale). "weekday" and
			// "weekend" are also accepted. Defaults to running
			// the check on any day of the week.
			only_run_on?: [...string]

			// The percentage delta between the source
			// directories file count and the most recent backup
			// archive file count that is allowed before the
			// entire consistency check fails. This can catch
			// problems like incorrect excludes, inadvertent
			// deletes, etc. Required (and only valid) for the
			// "spot" check.
			count_tolerance_percentage!: number

			// The percentage of total files in the source
			// directories to randomly sample and compare to
			// their corresponding files in the most recent
			// backup archive. Required (and only valid) for the
			// "spot" check.
			data_sample_percentage!: number

			// The percentage of total files in the source
			// directories that can fail a spot check comparison
			// without failing the entire consistency check. This
			// can catch problems like source files that have
			// been bulk-changed by malware, backups that have
			// been tampered with, etc. The value must be lower
			// than or equal to the "contents_sample_percentage".
			// Required (and only valid) for the "spot" check.
			data_tolerance_percentage!: number

			// Command to use instead of "xxh64sum" to hash
			// source files, usually found in an OS package named
			// "xxhash". Do not substitute with a different hash
			// type (SHA, MD5, etc.) or the check will never
			// succeed. Only valid for the "spot" check.
			xxh64sum_command?: string
		})])]

		// Paths or labels for a subset of the configured "repositories"
		// (see
		// above) on which to run consistency checks. Handy in case some
		// of
		// your repositories are very large, and so running consistency
		// checks
		// on them would take too long. Defaults to running consistency
		// checks
		// on all configured repositories.
		check_repositories?: [...string]

		// Restrict the number of checked archives to the last n. Applies
		// only
		// to the "archives" check. Defaults to checking all archives.
		check_last?: int

		// Apply color to console output. Defaults to true.
		color?: bool

		// Display verbose output to the console: -2 (disabled), -1
		// (errors
		// only), 0 (warnings and responses to actions, the default), 1
		// (info
		// about steps borgmatic is taking), or 2 (debug).
		verbosity?: (-2 | -1 | 0 | 1 | 2) & int

		// Log verbose output to syslog: -2 (disabled, the default), -1
		// (errors
		// only), 0 (warnings and responses to actions), 1 (info about
		// steps
		// borgmatic is taking), or 2 (debug).
		syslog_verbosity?: (-2 | -1 | 0 | 1 | 2) & int

		// Log verbose output to file: -2 (disabled), -1 (errors only), 0
		// (warnings and responses to actions), 1 (info about steps
		// borgmatic
		// is taking, the default), or 2 (debug).
		log_file_verbosity?: (-2 | -1 | 0 | 1 | 2) & int

		// Write log messages to the file at this path.
		log_file?: string

		// Python format string used for log messages written to the log
		// file.
		log_file_format?: string

		// When a monitoring integration supporting logging is configured,
		// log
		// verbose output to it: -2 (disabled), -1 (errors only), 0
		// (warnings
		// and responses to actions), 1 (info about steps borgmatic is
		// taking,
		// the default), or 2 (debug).
		monitoring_verbosity?: (-2 | -1 | 0 | 1 | 2) & int

		// Write Borg log messages and console output as one JSON object
		// per
		// log line instead of formatted text. Defaults to false.
		log_json?: bool

		// Display progress as each file or archive is processed when
		// running
		// supported actions. Corresponds to the "--progress" flag on
		// those
		// actions. Defaults to false.
		progress?: bool

		// Display statistics for an archive when running supported
		// actions.
		// Corresponds to the "--stats" flag on those actions. Defaults to
		// false.
		statistics?: bool

		// Display details for each file or archive as it is processed
		// when
		// running supported actions. Corresponds to the "--list" flag on
		// those
		// actions. Defaults to false.
		list_details?: bool

		// Whether to apply default actions (create, prune, compact and
		// check)
		// when no arguments are supplied to the borgmatic command. If set
		// to
		// false, borgmatic displays the help message instead.
		default_actions?: bool

		// List of one or more actions to skip running for this
		// configuration
		// file, even if specified on the command-line (explicitly or
		// implicitly). This is handy for append-only configurations where
		// you
		// never want to run "compact" or checkless configuration where
		// you
		// want to skip "check". Defaults to not skipping any actions.
		skip_actions?: [..."repo-create" | "transfer" | "prune" | "compact" | "create" | "recreate" | "check" | "delete" | "extract" | "config" | "export-tar" | "mount" | "umount" | "repo-delete" | "restore" | "repo-list" | "list" | "repo-info" | "info" | "break-lock" | "key" | "borg"]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before all the actions for each
		// repository.
		before_actions?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before creating a backup, run
		// once
		// per repository.
		before_backup?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before pruning, run once per
		// repository.
		before_prune?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before compaction, run once per
		// repository.
		before_compact?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before consistency checks, run
		// once
		// per repository.
		before_check?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before extracting a backup, run
		// once
		// per repository.
		before_extract?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after creating a backup, run
		// once per
		// repository.
		after_backup?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after compaction, run once per
		// repository.
		after_compact?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after pruning, run once per
		// repository.
		after_prune?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after consistency checks, run
		// once
		// per repository.
		after_check?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after extracting a backup, run
		// once
		// per repository.
		after_extract?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after all actions for each
		// repository.
		after_actions?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute when an exception occurs during
		// a
		// "create", "prune", "compact", or "check" action or an
		// associated
		// before/after hook.
		on_error?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute before running all actions (if
		// one of
		// them is "create"). These are collected from all configuration
		// files
		// and then run once before all of them (prior to all actions).
		before_everything?: [...string]

		// Deprecated. Use "commands:" instead. List of one or more shell
		// commands or scripts to execute after running all actions (if
		// one of
		// them is "create"). These are collected from all configuration
		// files
		// and then run once after all of them (after any action).
		after_everything?: [...string]

		// List of one or more command hooks to execute, triggered at
		// particular points during borgmatic's execution. For each
		// command
		// hook, specify one of "before" or "after", not both.
		commands?: [...matchN(1, [close({
			// Name for the point in borgmatic's execution that
			// the commands should be run before (required if
			// "after" isn't set):
			// * "action" runs before each action for each
			// repository.
			// * "repository" runs before all actions for each
			// repository.
			// * "configuration" runs before all actions and
			// repositories in the current configuration file.
			// * "everything" runs before all configuration
			// files.
			before!: "action" | "repository" | "configuration" | "everything"

			// List of actions for which the commands will be
			// run. Defaults to running for all actions.
			when?: [..."repo-create" | "transfer" | "prune" | "compact" | "create" | "recreate" | "check" | "delete" | "extract" | "config" | "export-tar" | "mount" | "umount" | "repo-delete" | "restore" | "repo-list" | "list" | "repo-info" | "info" | "break-lock" | "key" | "borg"]

			// List of one or more shell commands or scripts to
			// run when this command hook is triggered. Required.
			run!: [...string]
		}), close({
			// Name for the point in borgmatic's execution that
			// the commands should be run after (required if
			// "before" isn't set):
			// * "action" runs after each action for each
			// repository.
			// * "repository" runs after all actions for each
			// repository.
			// * "configuration" runs after all actions and
			// repositories in the current configuration file.
			// * "everything" runs after all configuration
			// files.
			// * "error" runs after an error occurs.
			after!: "action" | "repository" | "configuration" | "everything" | "error"

			// Only trigger the hook when borgmatic is run with
			// particular actions listed here. Defaults to
			// running for all actions.
			when?: [..."repo-create" | "transfer" | "prune" | "compact" | "create" | "recreate" | "check" | "delete" | "extract" | "config" | "export-tar" | "mount" | "umount" | "repo-delete" | "restore" | "repo-list" | "list" | "repo-info" | "info" | "break-lock" | "key" | "borg"]

			// Only trigger the hook if borgmatic encounters one
			// of the states (execution results) listed here,
			// where:
			// * "finish": No errors occurred.
			// * "fail": An error occurred.
			// This state is evaluated only for the scope of the
			// configured "action", "repository", etc., rather
			// than for the entire borgmatic run. Only available
			// for "after" hooks. Defaults to running the hook
			// for all states.
			states?: [..."finish" | "fail"]

			// List of one or more shell commands or scripts to
			// run when this command hook is triggered. Required.
			run!: [...string]
		})])]

		// Support for the "borgmatic bootstrap" action, used to extract
		// borgmatic configuration files from a backup archive.
		bootstrap?: close({
			// Store configuration files used to create a backup inside the
			// backup itself. Defaults to true. Changing this to false
			// prevents "borgmatic bootstrap" from extracting configuration
			// files from the backup.
			store_config_files?: bool
		})

		// List of one or more PostgreSQL databases to dump before
		// creating a
		// backup, run once per configuration file. The database dumps are
		// added to your source directories at runtime and streamed
		// directly
		// to Borg. Requires pg_dump/pg_dumpall/pg_restore commands. See
		// https://www.postgresql.org/docs/current/app-pgdump.html and
		// https://www.postgresql.org/docs/current/libpq-ssl.html for
		// details.
		postgresql_databases?: [...close({
			// Database name (required if using this hook). Or "all" to
			// dump all databases on the host. (Also set the "format"
			// to dump each database to a separate file instead of one
			// combined file.) Note that using this database hook
			// implicitly enables read_special (see above) to support
			// dump and restore streaming.
			name!: string

			// Label to identify the database dump in the backup.
			label?: string

			// Container name/id to connect to. When specified the
			// hostname is ignored. Requires docker/podman CLI.
			container?: string

			// Container name/id to restore to. Defaults to the
			// "container" option.
			restore_container?: string

			// Database hostname to connect to. Defaults to connecting
			// via local Unix socket.
			hostname?: string

			// Database hostname to restore to. Defaults to the
			// "hostname" option.
			restore_hostname?: string

			// Port to connect to. Defaults to 5432.
			port?: int

			// Port to restore to. Defaults to the "port" option.
			restore_port?: int

			// Username with which to connect to the database. Defaults
			// to the username of the current user. You probably want
			// to specify the "postgres" superuser here when the
			// database name is "all". Supports the "{credential ...}"
			// syntax.
			username?: string

			// Username with which to restore the database. Defaults to
			// the "username" option. Supports the "{credential ...}"
			// syntax.
			restore_username?: string

			// Password with which to connect to the database. Omitting
			// a password will only work if PostgreSQL is configured to
			// trust the configured username without a password or you
			// create a ~/.pgpass file. Supports the "{credential ...}"
			// syntax.
			password?: string

			// Password with which to connect to the restore database.
			// Defaults to the "password" option. Supports the
			// "{credential ...}" syntax.
			restore_password?: string

			// Do not output commands to set ownership of objects to
			// match the original database. By default, pg_dump and
			// pg_restore issue ALTER OWNER or SET SESSION
			// AUTHORIZATION statements to set ownership of created
			// schema elements. These statements will fail unless the
			// initial connection to the database is made by a
			// superuser.
			no_owner?: bool

			// Database dump output format. One of "plain", "custom",
			// "directory", or "tar". Defaults to "custom" (unlike raw
			// pg_dump) for a single database. Or, when database name
			// is "all" and format is blank, dumps all databases to a
			// single file. But if a format is specified with an "all"
			// database name, dumps each database to a separate file of
			// that format, allowing more convenient restores of
			// individual databases. See the pg_dump documentation for
			// more about formats.
			format?: "plain" | "custom" | "directory" | "tar"

			// Database dump compression level (integer) or method
			// ("gzip", "lz4", "zstd", or "none") and optional
			// colon-separated detail. Defaults to moderate "gzip" for
			// "custom" and "directory" formats and no compression for
			// the "plain" format. Compression is not supported for the
			// "tar" format. Be aware that Borg does its own
			// compression as well, so you may not need it in both
			// places.
			compression?: int | string

			// SSL mode to use to connect to the database server. One
			// of "disable", "allow", "prefer", "require", "verify-ca"
			// or "verify-full". Defaults to "disable".
			ssl_mode?: "disable" | "allow" | "prefer" | "require" | "verify-ca" | "verify-full"

			// Path to a client certificate.
			ssl_cert?: string

			// Path to a private client key.
			ssl_key?: string

			// Path to a root certificate containing a list of trusted
			// certificate authorities.
			ssl_root_cert?: string

			// Path to a certificate revocation list.
			ssl_crl?: string

			// Command to use instead of "pg_dump" or "pg_dumpall".
			// This can be used to run a specific pg_dump version
			// (e.g., one inside a running container). If you run it
			// from within a container, make sure to mount the path in
			// the "user_runtime_directory" option from the host into
			// the container at the same location. Defaults to
			// "pg_dump" for single database dump or "pg_dumpall" to
			// dump all databases.
			pg_dump_command?: string

			// Command to use instead of "pg_restore". This can be used
			// to run a specific pg_restore version (e.g., one inside a
			// running container). Defaults to "pg_restore".
			pg_restore_command?: string

			// Command to use instead of "psql". This can be used to
			// run a specific psql version (e.g., one inside a running
			// container). Defaults to "psql".
			psql_command?: string

			// Additional pg_dump/pg_dumpall options to pass directly
			// to the dump command, without performing any validation
			// on them. See pg_dump documentation for details.
			options?: string

			// Additional psql options to pass directly to the psql
			// command that lists available databases, without
			// performing any validation on them. See psql
			// documentation for details.
			list_options?: string

			// Additional pg_restore/psql options to pass directly to
			// the restore command, without performing any validation
			// on them. See pg_restore/psql documentation for details.
			restore_options?: string

			// Additional psql options to pass directly to the analyze
			// command run after a restore, without performing any
			// validation on them. See psql documentation for details.
			analyze_options?: string
		})]

		// List of one or more MariaDB databases to dump before creating a
		// backup, run once per configuration file. The database dumps are
		// added to your source directories at runtime and streamed
		// directly
		// to Borg. Requires mariadb-dump/mariadb commands. See
		// https://mariadb.com/kb/en/library/mysqldump/ for details.
		mariadb_databases?: [...close({
			// Database name (required if using this hook). Or "all" to
			// dump all databases on the host. Note that using this
			// database hook implicitly enables read_special (see
			// above) to support dump and restore streaming.
			name!: string

			// Database names to skip when dumping "all" databases.
			// Ignored when the database name is not "all".
			skip_names?: [...string]

			// Label to identify the database dump in the backup.
			label?: string

			// Container name/id to connect to. When specified the
			// hostname is ignored. Requires docker/podman CLI.
			container?: string

			// Container name/id to restore to. Defaults to the
			// "container" option.
			restore_container?: string

			// Database hostname to connect to. Defaults to connecting
			// via local Unix socket.
			hostname?: string

			// Database hostname to restore to. Defaults to the
			// "hostname" option.
			restore_hostname?: string

			// Port to connect to. Defaults to 3306.
			port?: int

			// Port to restore to. Defaults to the "port" option.
			restore_port?: int

			// Username with which to connect to the database. Defaults
			// to the username of the current user. Supports the
			// "{credential ...}" syntax.
			username?: string

			// Username with which to restore the database. Defaults to
			// the "username" option. Supports the "{credential ...}"
			// syntax.
			restore_username?: string

			// Password with which to connect to the database. Omitting
			// a password will only work if MariaDB is configured to
			// trust the configured username without a password.
			// Supports the "{credential ...}" syntax.
			password?: string

			// Password with which to connect to the restore database.
			// Defaults to the "password" option. Supports the
			// "{credential ...}" syntax.
			restore_password?: string

			// How to transmit database passwords from borgmatic to the
			// MariaDB client, one of:
			// * "pipe": Securely transmit passwords via anonymous
			// pipe. Only works if the database client is on the
			// same host as borgmatic. (The server can be
			// somewhere else.) This is the default value.
			// * "environment": Transmit passwords via environment
			// variable. Potentially less secure than a pipe, but
			// necessary when the database client is elsewhere, e.g.
			// when "mariadb_dump_command" is configured to "exec"
			// into a container and run a client there.
			password_transport?: "pipe" | "environment"

			// Whether to TLS-encrypt data transmitted between the
			// client and server. The default varies based on the
			// MariaDB version.
			tls?: bool

			// Whether to TLS-encrypt data transmitted between the
			// client and restore server. The default varies based on
			// the MariaDB version.
			restore_tls?: bool

			// Command to use instead of "mariadb-dump". This can be
			// used to run a specific mariadb_dump version (e.g., one
			// inside a running container). If you run it from within a
			// container, make sure to mount the path in the
			// "user_runtime_directory" option from the host into the
			// container at the same location. Defaults to
			// "mariadb-dump".
			mariadb_dump_command?: string

			// Command to run instead of "mariadb". This can be used to
			// run a specific mariadb version (e.g., one inside a
			// running container). Defaults to "mariadb".
			mariadb_command?: string

			// Database dump output format. Currently only "sql" is
			// supported. Defaults to "sql" for a single database. Or,
			// when database name is "all" and format is blank, dumps
			// all databases to a single file. But if a format is
			// specified with an "all" database name, dumps each
			// database to a separate file of that format, allowing
			// more convenient restores of individual databases.
			format?: "sql"

			// Use the "--add-drop-database" flag with mariadb-dump,
			// causing the database to be dropped right before restore.
			// Defaults to true.
			add_drop_database?: bool

			// Additional mariadb-dump options to pass directly to the
			// dump command, without performing any validation on them.
			// See mariadb-dump documentation for details.
			options?: string

			// Additional options to pass directly to the mariadb
			// command that lists available databases, without
			// performing any validation on them. See mariadb command
			// documentation for details.
			list_options?: string

			// Additional options to pass directly to the mariadb
			// command that restores database dumps, without
			// performing any validation on them. See mariadb command
			// documentation for details.
			restore_options?: string
		})]

		// List of one or more MySQL databases to dump before creating a
		// backup, run once per configuration file. The database dumps are
		// added to your source directories at runtime and streamed
		// directly
		// to Borg. Requires mysqldump/mysql commands. See
		// https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html for
		// details.
		mysql_databases?: [...close({
			// Database name (required if using this hook). Or "all" to
			// dump all databases on the host. Note that using this
			// database hook implicitly enables read_special (see
			// above) to support dump and restore streaming.
			name!: string

			// Database names to skip when dumping "all" databases.
			// Ignored when the database name is not "all".
			skip_names?: [...string]

			// Label to identify the database dump in the backup.
			label?: string

			// Container name/id to connect to. When specified the
			// hostname is ignored. Requires docker/podman CLI.
			container?: string

			// Container name/id to restore to. Defaults to the
			// "container" option.
			restore_container?: string

			// Database hostname to connect to. Defaults to connecting
			// via local Unix socket.
			hostname?: string

			// Database hostname to restore to. Defaults to the
			// "hostname" option.
			restore_hostname?: string

			// Port to connect to. Defaults to 3306.
			port?: int

			// Port to restore to. Defaults to the "port" option.
			restore_port?: int

			// Username with which to connect to the database. Defaults
			// to the username of the current user. Supports the
			// "{credential ...}" syntax.
			username?: string

			// Username with which to restore the database. Defaults to
			// the "username" option. Supports the "{credential ...}"
			// syntax.
			restore_username?: string

			// Password with which to connect to the database. Omitting
			// a password will only work if MySQL is configured to
			// trust the configured username without a password.
			// Supports the "{credential ...}" syntax.
			password?: string

			// Password with which to connect to the restore database.
			// Defaults to the "password" option. Supports the
			// "{credential ...}" syntax.
			restore_password?: string

			// How to transmit database passwords from borgmatic to the
			// MySQL client, one of:
			// * "pipe": Securely transmit passwords via anonymous
			// pipe. Only works if the database client is on the
			// same host as borgmatic. (The server can be
			// somewhere else.) This is the default value.
			// * "environment": Transmit passwords via environment
			// variable. Potentially less secure than a pipe, but
			// necessary when the database client is elsewhere, e.g.
			// when "mysql_dump_command" is configured to "exec"
			// into a container and run a client there.
			password_transport?: "pipe" | "environment"

			// Whether to TLS-encrypt data transmitted between the
			// client and server. The default varies based on the
			// MySQL installation.
			tls?: bool

			// Whether to TLS-encrypt data transmitted between the
			// client and restore server. The default varies based on
			// the MySQL installation.
			restore_tls?: bool

			// Command to use instead of "mysqldump". This can be used
			// to run a specific mysql_dump version (e.g., one inside a
			// running container). If you run it from within a
			// container, make sure to mount the path in the
			// "user_runtime_directory" option from the host into the
			// container at the same location. Defaults to "mysqldump".
			mysql_dump_command?: string

			// Command to run instead of "mysql". This can be used to
			// run a specific mysql version (e.g., one inside a running
			// container). Defaults to "mysql".
			mysql_command?: string

			// Database dump output format. Currently only "sql" is
			// supported. Defaults to "sql" for a single database. Or,
			// when database name is "all" and format is blank, dumps
			// all databases to a single file. But if a format is
			// specified with an "all" database name, dumps each
			// database to a separate file of that format, allowing
			// more convenient restores of individual databases.
			format?: "sql"

			// Use the "--add-drop-database" flag with mysqldump,
			// causing the database to be dropped right before restore.
			// Defaults to true.
			add_drop_database?: bool

			// Additional mysqldump options to pass directly to the
			// dump command, without performing any validation on them.
			// See mysqldump documentation for details.
			options?: string

			// Additional options to pass directly to the mysql
			// command that lists available databases, without
			// performing any validation on them. See mysql command
			// documentation for details.
			list_options?: string

			// Additional options to pass directly to the mysql
			// command that restores database dumps, without
			// performing any validation on them. See mysql command
			// documentation for details.
			restore_options?: string
		})]

		// List of one or more SQLite databases to dump before creating a
		// backup, run once per configuration file. The database dumps are
		// added to your source directories at runtime and streamed
		// directly to
		// Borg. Requires the sqlite3 command. See
		// https://sqlite.org/cli.html
		// for details.
		sqlite_databases?: [...close({
			// This is used to tag the database dump file with a name.
			// It is not the path to the database file itself. The name
			// "all" has no special meaning for SQLite databases.
			name!: string

			// Path to the SQLite database file to dump. If relative,
			// it is relative to the current working directory. Note
			// that using this database hook implicitly enables
			// read_special (see above) to support dump and restore
			// streaming.
			path!: string

			// Label to identify the database dump in the backup.
			label?: string

			// Path to the SQLite database file to restore to. Defaults
			// to the "path" option.
			restore_path?: string

			// Command to use instead of "sqlite3". This can be used to
			// run a specific sqlite3 version (e.g., one inside a
			// running container). If you run it from within a
			// container, make sure to mount the path in the
			// "user_runtime_directory" option from the host into the
			// container at the same location. Defaults to "sqlite3".
			sqlite_command?: string

			// Command to run when restoring a database instead
			// of "sqlite3". This can be used to run a specific
			// sqlite3 version (e.g., one inside a running container).
			// Defaults to "sqlite3".
			sqlite_restore_command?: string
		})]

		// List of one or more MongoDB databases to dump before creating a
		// backup, run once per configuration file. The database dumps are
		// added to your source directories at runtime and streamed
		// directly
		// to Borg. Requires mongodump/mongorestore commands. See
		// https://docs.mongodb.com/database-tools/mongodump/ and
		// https://docs.mongodb.com/database-tools/mongorestore/ for
		// details.
		mongodb_databases?: [...close({
			// Database name (required if using this hook). Or "all" to
			// dump all databases on the host. Note that using this
			// database hook implicitly enables read_special (see
			// above) to support dump and restore streaming.
			name!: string

			// Label to identify the database dump in the backup.
			label?: string

			// Container name/id to connect to. When specified the
			// hostname is ignored. Requires docker/podman CLI.
			container?: string

			// Container name/id to restore to. Defaults to the
			// "container" option.
			restore_container?: string

			// Database hostname to connect to. Defaults to connecting
			// to localhost.
			hostname?: string

			// Database hostname to restore to. Defaults to the
			// "hostname" option.
			restore_hostname?: string

			// Port to connect to. Defaults to 27017.
			port?: int

			// Port to restore to. Defaults to the "port" option.
			restore_port?: int

			// Username with which to connect to the database. Skip it
			// if no authentication is needed. Supports the
			// "{credential ...}" syntax.
			username?: string

			// Username with which to restore the database. Defaults to
			// the "username" option. Supports the "{credential ...}"
			// syntax.
			restore_username?: string

			// Password with which to connect to the database. Skip it
			// if no authentication is needed. Supports the
			// "{credential ...}" syntax.
			password?: string

			// Password with which to connect to the restore database.
			// Defaults to the "password" option. Supports the
			// "{credential ...}" syntax.
			restore_password?: string

			// Authentication database where the specified username
			// exists. If no authentication database is specified, the
			// database provided in "name" is used. If "name" is "all",
			// the "admin" database is used.
			authentication_database?: string

			// Database dump output format. One of "archive", or
			// "directory". Defaults to "archive". See mongodump
			// documentation for details. Note that format is ignored
			// when the database name is "all".
			format?: "archive" | "directory"

			// Additional mongodump options to pass directly to the
			// dump command, without performing any validation on them.
			// See mongodump documentation for details.
			options?: string

			// Additional mongorestore options to pass directly to the
			// dump command, without performing any validation on them.
			// See mongorestore documentation for details.
			restore_options?: string

			// Command to use instead of "mongodump". This can be used
			// to run a specific mongodump version (e.g., one inside a
			// running container). If you run it from within a
			// container, make sure to mount the path in the
			// "user_runtime_directory" option from the host into the
			// container at the same location. Defaults to
			// "mongodump".
			mongodump_command?: string

			// Command to run when restoring a database instead of
			// "mongorestore". This can be used to run a specific
			// mongorestore version (e.g., one inside a running
			// container). Defaults to "mongorestore".
			mongorestore_command?: string
		})]
		ntfy?: close({
			// The topic to publish to. See https://ntfy.sh/docs/publish/
			// for details.
			topic!: string

			// The address of your self-hosted ntfy.sh instance.
			server?: string

			// The username used for authentication. Supports the
			// "{credential ...}" syntax.
			username?: string

			// The password used for authentication. Supports the
			// "{credential ...}" syntax.
			password?: string

			// An ntfy access token to authenticate with instead of
			// username/password. Supports the "{credential ...}" syntax.
			access_token?: string
			start?: close({
				// The title of the message.
				title?: string

				// The message body to publish.
				message?: string

				// The priority to set.
				priority?: string

				// Tags to attach to the message.
				tags?: string
			})
			finish?: close({
				// The title of the message.
				title?: string

				// The message body to publish.
				message?: string

				// The priority to set.
				priority?: string

				// Tags to attach to the message.
				tags?: string
			})
			fail?: close({
				// The title of the message.
				title?: string

				// The message body to publish.
				message?: string

				// The priority to set.
				priority?: string

				// Tags to attach to the message.
				tags?: string
			})

			// List of one or more monitoring states to ping for: "start",
			// "finish", and/or "fail". Defaults to pinging for failure
			// only.
			states?: [..."start" | "finish" | "fail"]
		})
		pushover?: close({
			// Your application's API token. Supports the "{credential
			// ...}" syntax.
			token!: string

			// Your user/group key (or that of your target user), viewable
			// when logged into your dashboard: often referred to as
			// USER_KEY in Pushover documentation and code examples.
			// Supports the "{credential ...}" syntax.
			user!: string
			start?: close({
				// Message to be sent to the user or group. If omitted
				// the default is the name of the state.
				message?: string

				// A value of -2, -1, 0 (default), 1 or 2 that
				// indicates the message priority.
				priority?: int

				// How many seconds your notification will continue
				// to be retried (every retry seconds). Defaults to
				// 600. This settings only applies to priority 2
				// notifications.
				expire?: int

				// The retry parameter specifies how often
				// (in seconds) the Pushover servers will send the
				// same notification to the user. Defaults to 30. This
				// settings only applies to priority 2 notifications.
				retry?: int

				// The name of one of your devices to send just to
				// that device instead of all devices.
				device?: string

				// Set to True to enable HTML parsing of the message.
				// Set to false for plain text.
				html?: bool

				// The name of a supported sound to override your
				// default sound choice. All options can be found
				// here: https://pushover.net/api#sounds
				sound?: string

				// Your message's title, otherwise your app's name is
				// used.
				title?: string

				// The number of seconds that the message will live,
				// before being deleted automatically. The ttl
				// parameter is ignored for messages with a priority.
				// value of 2.
				ttl?: int

				// A supplementary URL to show with your message.
				url?: string

				// A title for the URL specified as the url parameter,
				// otherwise just the URL is shown.
				url_title?: string
			})
			finish?: close({
				// Message to be sent to the user or group. If omitted
				// the default is the name of the state.
				message?: string

				// A value of -2, -1, 0 (default), 1 or 2 that
				// indicates the message priority.
				priority?: int

				// How many seconds your notification will continue
				// to be retried (every retry seconds). Defaults to
				// 600. This settings only applies to priority 2
				// notifications.
				expire?: int

				// The retry parameter specifies how often
				// (in seconds) the Pushover servers will send the
				// same notification to the user. Defaults to 30. This
				// settings only applies to priority 2 notifications.
				retry?: int

				// The name of one of your devices to send just to
				// that device instead of all devices.
				device?: string

				// Set to True to enable HTML parsing of the message.
				// Set to false for plain text.
				html?: bool

				// The name of a supported sound to override your
				// default sound choice. All options can be found
				// here: https://pushover.net/api#sounds
				sound?: string

				// Your message's title, otherwise your app's name is
				// used.
				title?: string

				// The number of seconds that the message will live,
				// before being deleted automatically. The ttl
				// parameter is ignored for messages with a priority.
				// value of 2.
				ttl?: int

				// A supplementary URL to show with your message.
				url?: string

				// A title for the URL specified as the url parameter,
				// otherwise just the URL is shown.
				url_title?: string
			})
			fail?: close({
				// Message to be sent to the user or group. If omitted
				// the default is the name of the state.
				message?: string

				// A value of -2, -1, 0 (default), 1 or 2 that
				// indicates the message priority.
				priority?: int

				// How many seconds your notification will continue
				// to be retried (every retry seconds). Defaults to
				// 600. This settings only applies to priority 2
				// notifications.
				expire?: int

				// The retry parameter specifies how often
				// (in seconds) the Pushover servers will send the
				// same notification to the user. Defaults to 30. This
				// settings only applies to priority 2 notifications.
				retry?: int

				// The name of one of your devices to send just to
				// that device instead of all devices.
				device?: string

				// Set to True to enable HTML parsing of the message.
				// Set to false for plain text.
				html?: bool

				// The name of a supported sound to override your
				// default sound choice. All options can be found
				// here: https://pushover.net/api#sounds
				sound?: string

				// Your message's title, otherwise your app's name is
				// used.
				title?: string

				// The number of seconds that the message will live,
				// before being deleted automatically. The ttl
				// parameter is ignored for messages with a priority.
				// value of 2.
				ttl?: int

				// A supplementary URL to show with your message.
				url?: string

				// A title for the URL specified as the url parameter,
				// otherwise just the URL is shown.
				url_title?: string
			})

			// List of one or more monitoring states to ping for: "start",
			// "finish", and/or "fail". Defaults to pinging for failure
			// only.
			states?: [..."start" | "finish" | "fail"]
		})
		zabbix?: close({
			// The ID of the Zabbix item used for collecting data.
			// Unique across the entire Zabbix system.
			itemid?: int

			// Host name where the item is stored. Required if "itemid"
			// is not set.
			host?: string

			// Key of the host where the item is stored. Required if
			// "itemid" is not set.
			key?: string

			// The API endpoint URL of your Zabbix instance, usually ending
			// with "/api_jsonrpc.php". Required.
			server!: string

			// The username used for authentication. Not needed if using
			// an API key. Supports the "{credential ...}" syntax.
			username?: string

			// The password used for authentication. Not needed if using
			// an API key. Supports the "{credential ...}" syntax.
			password?: string

			// The API key used for authentication. Not needed if using an
			// username/password. Supports the "{credential ...}" syntax.
			api_key?: string
			start?: close({
				// The value to set the item to on start.
				value?: int | string
			})
			finish?: close({
				// The value to set the item to on finish.
				value?: int | string
			})
			fail?: close({
				// The value to set the item to on fail.
				value?: int | string
			})

			// List of one or more monitoring states to ping for: "start",
			// "finish", and/or "fail". Defaults to pinging for failure
			// only.
			states?: [..."start" | "finish" | "fail"]
		})
		apprise?: close({
			// A list of Apprise services to publish to with URLs and
			// labels. The labels are used for logging. A full list of
			// services and their configuration can be found at
			// https://github.com/caronc/apprise/wiki.
			services!: [...close({
				// URL of this Apprise service.
				url!: string

				// Label used in borgmatic logs for this Apprise
				// service.
				label!: string
			})]

			// Send borgmatic logs to Apprise services as part of the
			// "finish", "fail", and "log" states. Defaults to true.
			send_logs?: bool

			// Number of bytes of borgmatic logs to send to Apprise
			// services. Set to 0 to send all logs and disable this
			// truncation. Defaults to 1500.
			logs_size_limit?: int
			start?: close({
				// Specify the message title. If left unspecified, no
				// title is sent.
				title?: string

				// Specify the message body.
				body!: string
			})
			finish?: close({
				// Specify the message title. If left unspecified, no
				// title is sent.
				title?: string

				// Specify the message body.
				body!: string
			})
			fail?: close({
				// Specify the message title. If left unspecified, no
				// title is sent.
				title?: string

				// Specify the message body.
				body!: string
			})
			log?: close({
				// Specify the message title. If left unspecified, no
				// title is sent.
				title?: string

				// Specify the message body.
				body!: string
			})

			// List of one or more monitoring states to ping for:
			// "start", "finish", "fail", and/or "log". Defaults to
			// pinging for failure only. For each selected state,
			// corresponding configuration for the message title and body
			// should be given. If any is left unspecified, a generic
			// message is emitted instead.
			states?: [..."start" | "finish" | "fail" | "log"]
		})

		// Configuration for a monitoring integration with Healthchecks.
		// Create
		// an account at https://healthchecks.io (or self-host
		// Healthchecks) if
		// you'd like to use this service. See borgmatic monitoring
		// documentation for details.
		healthchecks?: close({
			// Healthchecks ping URL or UUID to notify when a backup
			// begins, ends, errors, or to send only logs.
			ping_url!: string

			// Verify the TLS certificate of the ping URL host. Defaults to
			// true.
			verify_tls?: bool

			// Send borgmatic logs to Healthchecks as part of the "finish",
			// "fail", and "log" states. Defaults to true.
			send_logs?: bool

			// Number of bytes of borgmatic logs to send to Healthchecks,
			// ideally the same as PING_BODY_LIMIT configured on the
			// Healthchecks server. Set to 0 to send all logs and disable
			// this truncation. Defaults to 100000.
			ping_body_limit?: int

			// List of one or more monitoring states to ping for: "start",
			// "finish", "fail", and/or "log". Defaults to pinging for all
			// states.
			states?: [..."start" | "finish" | "fail" | "log"]

			// Create the check if it does not exist. Only works with
			// the slug URL scheme (https://hc-ping.com/<ping-key>/<slug>
			// as opposed to https://hc-ping.com/<uuid>).
			// Defaults to false.
			create_slug?: bool
		})

		// Configuration for a monitoring integration with Uptime Kuma
		// using
		// the Push monitor type.
		// See more information here: https://uptime.kuma.pet
		uptime_kuma?: close({
			// Uptime Kuma push URL without query string (do not include the
			// question mark or anything after it).
			push_url!: string

			// List of one or more monitoring states to push for: "start",
			// "finish", and/or "fail". Defaults to pushing for all
			// states.
			states?: [..."start" | "finish" | "fail"]

			// Verify the TLS certificate of the push URL host. Defaults to
			// true.
			verify_tls?: bool
		})

		// Configuration for a monitoring integration with Cronitor.
		// Create an
		// account at https://cronitor.io if you'd like to use this
		// service.
		// See borgmatic monitoring documentation for details.
		cronitor?: close({
			// Cronitor ping URL to notify when a backup begins,
			// ends, or errors.
			ping_url!: string
		})

		// Configuration for a monitoring integration with PagerDuty.
		// Create an
		// account at https://www.pagerduty.com if you'd like to use this
		// service. See borgmatic monitoring documentation for details.
		pagerduty?: close({
			// PagerDuty integration key used to notify PagerDuty when a
			// backup errors. Supports the "{credential ...}" syntax.
			integration_key!: string

			// Send borgmatic logs to PagerDuty when a backup errors.
			// Defaults to true.
			send_logs?: bool
		})

		// Configuration for a monitoring integration with Cronhub. Create
		// an
		// account at https://cronhub.io if you'd like to use this
		// service. See
		// borgmatic monitoring documentation for details.
		cronhub?: close({
			// Cronhub ping URL to notify when a backup begins,
			// ends, or errors.
			ping_url!: string
		})

		// Configuration for a monitoring integration with Grafana Loki.
		// You
		// can send the logs to a self-hosted instance or create an
		// account at
		// https://grafana.com/auth/sign-up/create-user. See borgmatic
		// monitoring documentation for details.
		loki?: close({
			// Grafana loki log URL to notify when a backup begins,
			// ends, or fails.
			url!: string

			// Allows setting custom labels for the logging stream. At
			// least one label is required. "__hostname" gets replaced by
			// the machine hostname automatically. "__config" gets replaced
			// by the name of the configuration file. "__config_path" gets
			// replaced by the full path of the configuration file.
			labels!: [string]: string
		})

		// Configuration for a monitoring integration with Sentry. You can
		// use
		// a self-hosted instance via
		// https://develop.sentry.dev/self-hosted/
		// or create a cloud-hosted account at https://sentry.io. See
		// borgmatic
		// monitoring documentation for details.
		sentry?: close({
			// Sentry Data Source Name (DSN) URL, associated with a
			// particular Sentry project. Used to construct a cron URL,
			// notified when a backup begins, ends, or errors.
			data_source_name_url!: string

			// Sentry monitor slug, associated with a particular Sentry
			// project monitor. Used along with the data source name URL to
			// construct a cron URL.
			monitor_slug!: string

			// List of one or more monitoring states to ping for: "start",
			// "finish", and/or "fail". Defaults to pinging for all states.
			states?: [..."start" | "finish" | "fail"]
		})

		// Configuration for integration with the ZFS filesystem.
		zfs?: null | close({
			// Command to use instead of "zfs".
			zfs_command?: string

			// Command to use instead of "mount".
			mount_command?: string

			// Command to use instead of "umount".
			umount_command?: string
		})

		// Configuration for integration with the Btrfs filesystem.
		btrfs?: null | close({
			// Command to use instead of "btrfs".
			btrfs_command?: string

			// Deprecated and unused. Was the command to use instead of
			// "findmnt".
			findmnt_command?: string
		})

		// Configuration for integration with Linux LVM (Logical Volume
		// Manager).
		lvm?: null | close({
			// Size to allocate for each snapshot taken, including the
			// units to use for that size. Defaults to "10%ORIGIN" (10%
			// of the size of logical volume being snapshotted). See the
			// lvcreate "--size" and "--extents" documentation for more
			// information:
			// https://www.man7.org/linux/man-pages/man8/lvcreate.8.html
			snapshot_size?: string

			// Command to use instead of "lvcreate".
			lvcreate_command?: string

			// Command to use instead of "lvremove".
			lvremove_command?: string

			// Command to use instead of "lvs".
			lvs_command?: string

			// Command to use instead of "lsblk".
			lsblk_command?: string

			// Command to use instead of "mount".
			mount_command?: string

			// Command to use instead of "umount".
			umount_command?: string
		})

		// Configuration for integration with systemd credentials.
		systemd?: close({
			// Command to use instead of "systemd-creds". Only used as a
			// fallback when borgmatic is run outside of a systemd service.
			systemd_creds_command?: string

			// Directory containing encrypted credentials for
			// "systemd-creds" to use instead of
			// "/etc/credstore.encrypted".
			encrypted_credentials_directory?: string
		})

		// Configuration for integration with Docker or Podman secrets.
		container?: close({
			// Secrets directory to use instead of "/run/secrets".
			secrets_directory?: string
		})

		// Configuration for integration with the KeePassXC password
		// manager.
		keepassxc?: close({
			// Command to use instead of "keepassxc-cli".
			keepassxc_cli_command?: string

			// Path to a key file for unlocking the KeePassXC database.
			key_file?: string

			// YubiKey slot and optional serial number used to access the
			// KeePassXC database. The format is "<slot[:serial]>", where:
			// * <slot> is the YubiKey slot number (e.g., `1` or `2`).
			// * <serial> (optional) is the YubiKey's serial number (e.g.,
			// `7370001`).
			yubikey?: string
		})
	})
