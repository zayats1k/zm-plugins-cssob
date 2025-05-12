stock void TE_DynamicLight(const float origin[3], int r, int g, int b, int exponent, float radius, float time, float decay)
{
    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin", origin);
    TE_WriteNum("r", r);
    TE_WriteNum("g", g);
    TE_WriteNum("b", b);
    TE_WriteNum("exponent", exponent);
    TE_WriteFloat("m_fRadius", radius);
    TE_WriteFloat("m_fTime", time);
    TE_WriteFloat("m_fDecay", decay);
}