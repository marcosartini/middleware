configuration AppC{
}
implementation{
components MyAppP;
components MainC;
...
MyAppP.Boot --> MainC;
}
