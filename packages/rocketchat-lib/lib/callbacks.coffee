# https://github.com/TelescopeJS/Telescope/blob/master/packages/telescope-lib/lib/callbacks.js

###
# Callback hooks provide an easy way to add extra steps to common operations.
# @namespace RocketChat.callbacks
###
RocketChat.callbacks = {}

###
# Callback priorities
###
RocketChat.callbacks.priority =
	HIGH: -1
	MEDIUM: 0
	LOW: 1

###
# Add a callback function to a hook
# @param {String} hook - The name of the hook
# @param {Function} callback - The callback function
###

RocketChat.callbacks.add = (hook, callback, priority) ->
	# if callback array doesn't exist yet, initialize it
	priority ?= RocketChat.callbacks.priority.MEDIUM
	unless _.isNumber priority
		priority = RocketChat.callbacks.priority.MEDIUM
	callback.priority = priority
	RocketChat.callbacks[hook] ?= []
	RocketChat.callbacks[hook].push callback
	return

###
# Remove a callback from a hook
# @param {string} hook - The name of the hook
# @param {string} functionName - The name of the function to remove
###

RocketChat.callbacks.remove = (hookName, callbackName) ->
	RocketChat.callbacks[hookName] = _.reject RocketChat.callbacks[hookName], (callback) ->
		callback.name is callbackName
	return

###
# Successively run all of a hook's callbacks on an item
# @param {String} hook - The name of the hook
# @param {Object} item - The post, comment, modifier, etc. on which to run the callbacks
# @param {Object} [constant] - An optional constant that will be passed along to each callback
# @returns {Object} Returns the item after it's been through all the callbacks for this hook
###

RocketChat.callbacks.run = (hook, item, constant) ->
	callbacks = RocketChat.callbacks[hook]
	if !!callbacks?.length
		# if the hook exists, and contains callbacks to run
		_.sortBy(callbacks, (callback) -> return callback.priority or RocketChat.callbacks.priority.MEDIUM).reduce (result, callback) ->
			# console.log(callback.name);
			callback result, constant
		, item
	else
		# else, just return the item unchanged
		item

###
# Successively run all of a hook's callbacks on an item, in async mode (only works on server)
# @param {String} hook - The name of the hook
# @param {Object} item - The post, comment, modifier, etc. on which to run the callbacks
# @param {Object} [constant] - An optional constant that will be passed along to each callback
###

RocketChat.callbacks.runAsync = (hook, item, constant) ->
	callbacks = RocketChat.callbacks[hook]
	if Meteor.isServer and !!callbacks?.length
		# use defer to avoid holding up client
		Meteor.defer ->
			# run all post submit server callbacks on post object successively
			_.sortBy(callbacks, (callback) -> return callback.priority or RocketChat.callbacks.priority.MEDIUM).forEach (callback) ->
				# console.log(callback.name);
				callback item, constant
				return
			return
	else
		return item
	return
