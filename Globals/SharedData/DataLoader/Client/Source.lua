for Index: number, Module: ModuleScript in script.Parent.Parent:GetChildren() do
	if not Module:IsA(`ModuleScript`) then continue end
	task.spawn(require, Module)
end
