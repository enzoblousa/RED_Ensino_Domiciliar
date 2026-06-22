using MediaEscolar.Api.Models;
using Xunit;

namespace MediaEscolar.Tests;

public class CalculadoraTests
{
    [Fact]
    public void CalcularMedia_DeveRetornarMediaAritmeticaDasDuasNotas()
    {
        var media = Calculadora.CalcularMedia(8, 6);
        Assert.Equal(7, media);
    }

    [Fact]
    public void CalcularSituacao_DeveRetornarAprovadoQuandoMediaMaiorOuIgualASeis()
    {
        var situacao = Calculadora.CalcularSituacao(6.0);
        Assert.Equal("Aprovado", situacao);
    }

    [Fact]
    public void CalcularSituacao_DeveRetornarReprovadoQuandoMediaMenorQueSeis()
    {
        var situacao = Calculadora.CalcularSituacao(5.9);
        Assert.Equal("Reprovado", situacao);
    }

    [Fact]
    public void ValidarNota_DeveLancarExcecaoQuandoNotaForMaiorQueDez()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Calculadora.ValidarNota(10.1));
    }

    [Fact]
    public void ValidarNota_DeveLancarExcecaoQuandoNotaForMenorQueZero()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Calculadora.ValidarNota(-0.1));
    }

    [Fact]
    public void CalcularSituacao_RegressaoDaNotaDeCorteSeis()
    {
        Assert.Equal("Aprovado", Calculadora.CalcularSituacao(6.0));
        Assert.Equal("Reprovado", Calculadora.CalcularSituacao(5.99));
    }
}
