local R ={}
local observables = {}

function R.create_stream(message_id)
	observables[message_id] = observables[message_id] or {observers = {} }
end


function R.cancel_all_observing(self)
	for _, observable in pairs(observables) do
		for __,observer in pairs(observable.observers) do
			if observer.url == msg.url() then
				table.remove(observable.observers,__)
				break
			end
		end
	end
end


function R.cancel_observing(self,message_id)
	for index,rx in pairs(self.stream_list) do
		if rx.message_id == message_id then
			table.remove(self.stream_list,index)
			break
		end
	end
	for _,observer in pairs(observables[message_id].observers) do
		if observer.url == msg.url() then
			table.remove(observables[message_id].observers,_)
			break
		end
	end
end

function R.observe(self,message_id,func)
	self.stream_list = self.stream_list or {}
	func = func or nil
	if func then
		assert(observables[message_id], "You must create an observable before you can observe it")
		table.insert(observables[message_id].observers, {url=msg.url(),func=func})
	else
		assert(observables[message_id], "You must create an observable before you can observe it")
		table.insert(observables[message_id].observers, {url=msg.url()})
	end
	local stream = {message_id=hash(message_id),func=func}
	table.insert(self.stream_list, stream)
end

function R.on_message(self, message_id, message,sender)
	for _,rx in pairs(self.stream_list) do
		if message_id==rx.message_id then
			if rx.func then
				rx.func(self, message_id, message, sender)
			end
		end
	end
end

function R.notify(message_id, data)
	assert(observables[message_id], "You must create an observable before you can use it")
	data = data or {}
	for _,observer in pairs(observables[message_id].observers) do
		msg.post(observer.url, message_id, data)
	end
end


function R.create_reactive_property(value,message_id)
	observables[message_id] = observables[message_id] or {observers = {} }
	local prop = {value=value}
	function prop:set(value)
		prop.value=value
		R.notify(message_id, {value=prop.value})
	end
	return prop
end

return R