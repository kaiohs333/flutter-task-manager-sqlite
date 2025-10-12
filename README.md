# Gerenciador de Tarefas com SQLite em Flutter

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg) ![Dart](https://img.shields.io/badge/Dart-3.x-orange.svg) ![SQLite](https://img.shields.io/badge/SQLite-blue.svg)

> Projeto acadêmico para a disciplina de Desenvolvimento de Aplicações Móveis e Distribuídas, focado na implementação de um aplicativo de gerenciamento de tarefas com persistência de dados local utilizando SQLite.

---

### 📖 Índice

* [Sobre o Projeto](#-sobre-o-projeto)
* [Conceito Principal: Persistência Local](#-conceito-principal-persistência-local-com-sqlite)
* [✨ Features](#-features)
* [🛠️ Tecnologias Utilizadas](#️-tecnologias-utilizadas)
* [🚀 Como Executar o Projeto](#-como-executar-o-projeto)
* [👨‍💻 Autor](#-autor)

---

## 📱 Sobre o Projeto

Este projeto consiste em um aplicativo de **Gerenciamento de Tarefas** (`Task Manager`) desenvolvido com o framework Flutter. O objetivo principal é demonstrar a integração de um banco de dados local **SQLite** em uma aplicação Flutter, permitindo que os dados do usuário (as tarefas) persistam mesmo após o fechamento do aplicativo.

A aplicação permite ao usuário realizar operações de CRUD (Criar, Ler, Atualizar, Deletar) em suas tarefas, gerenciando o estado da interface de forma reativa e eficiente.

## 💾 Conceito Principal: Persistência Local com SQLite

Diferente do projeto anterior (lista de compras em memória), este aplicativo implementa a **persistência de dados**. Isso significa que as tarefas criadas pelo usuário são salvas em um arquivo de banco de dados no próprio dispositivo (ou no armazenamento do navegador, no caso da versão web).

Para isso, utilizamos o pacote `sqflite`, que é a principal solução da comunidade Flutter para interagir com bancos de dados SQLite. A lógica de banco de dados foi abstraída em uma classe de serviço (`DatabaseService`) que segue o padrão Singleton, garantindo uma única instância e conexão com o banco em toda a aplicação.

---

## ✨ Features

* **CRUD Completo de Tarefas:**
    * **Criar:** Adiciona novas tarefas com título e prioridade.
    * **Ler:** Exibe a lista de tarefas salvas no banco de dados.
    * **Atualizar:** Permite marcar uma tarefa como concluída, com feedback visual (texto riscado).
    * **Deletar:** Remove tarefas da lista e do banco de dados.
* **Seleção de Prioridade:** Um campo `Dropdown` permite ao usuário definir a prioridade (`low`, `medium`, `high`, `urgent`) ao criar uma nova tarefa.
* **Filtros de Exibição:** Botões de filtro (`FilterChip`) permitem visualizar a lista de tarefas por status: "Todas", "Pendentes" ou "Concluídas".
* **Contador de Tarefas:** O título do aplicativo exibe dinamicamente a quantidade de tarefas que estão sendo mostradas na lista filtrada.
* **Persistência de Dados:** Todas as tarefas são salvas localmente usando SQLite, garantindo que os dados não sejam perdidos ao fechar e reabrir o aplicativo.

---

## 🛠️ Tecnologias Utilizadas

* **[Flutter](https://flutter.dev/)**: Framework da Google para desenvolvimento multiplataforma.
* **[Dart](https://dart.dev/)**: Linguagem de programação utilizada pelo Flutter.
* **[SQLite](https://www.sqlite.org/index.html)**: Motor de banco de dados relacional embarcado, utilizado através do pacote `sqflite`.
* **[path_provider](https://pub.dev/packages/path_provider)**: Pacote para encontrar caminhos no sistema de arquivos do dispositivo.
* **[Visual Studio Code](https://code.visualstudio.com/)**: Editor de código com extensões para desenvolvimento Flutter.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

* **Flutter SDK** instalado e configurado.
* **Google Chrome** instalado (para executar a versão web).

### Passos

1.  Clone o repositório:
    ```bash
    git clone <url-do-seu-repositorio>
    ```
2.  Navegue até a pasta do projeto:
    ```bash
    cd task_manager
    ```
3.  Instale as dependências do projeto:
    ```bash
    flutter pub get
    ```
4.  Execute o aplicativo:
    ```bash
    flutter run -d chrome
    ```
    O comando acima irá iniciar o aplicativo no Google Chrome.

---

## 👨‍💻 Autor

* **Kaio Henrique Oliveira da Silveira Barbosa**
* **Email**: kaiohsilveira@gmail.com