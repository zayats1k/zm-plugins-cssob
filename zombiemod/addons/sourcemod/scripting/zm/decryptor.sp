int DecryptPrecacheModel(const char[] model)
{
	if (!hasLength(model))
	{
		return 0;
	}
	
	if (!FileExists(model))
	{
		if (FileExists(model, true))
		{
			return PrecacheModel(model, true);
		}
		
		LogError("[Decrypt] [Config Validation] Invalid model path. File not found: \"%s\"", model);
		return 0;
	}
	return PrecacheModel(model, true);
}