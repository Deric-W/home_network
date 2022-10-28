# ACME account configuration

{ ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "robo-eric@gmx.de";
    };
  };
}
